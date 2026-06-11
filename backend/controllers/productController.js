const { query, get, run } = require('../database');

// ===============================
// Products management (CRM side)
// ===============================

// List all products (admin can view)
async function listProducts(req, res) {
  try {
    const result = await query(
      `SELECT p.id, p.name, p.product_code, p.description, p.price, p.brand,
              p.category, p.variant, p.stock, p.valid_until, p.created_at,
              COUNT(d.id) AS registered_devices,
              SUM(CASE WHEN d.id IS NOT NULL AND d.assigned_user_id IS NULL THEN 1 ELSE 0 END) AS available_devices
       FROM products p
       LEFT JOIN devices d ON d.product_id = p.id
       GROUP BY p.id, p.name, p.product_code, p.description, p.price, p.brand,
                p.category, p.variant, p.stock, p.valid_until, p.created_at
       ORDER BY p.created_at DESC`
    );
    res.json(result.rows || result);
  } catch (err) {
    console.error('[Products] List error:', err);
    res.status(500).json({ error: 'server_error', message: 'Could not fetch products' });
  }
}

// Add a new product (admin only)
async function addProduct(req, res) {
  const {
    name,
    description,
    product_id,
    product_code,
    device_uid,
    price,
    brand,
    category,
    variant,
    stock,
    valid_until
  } = req.body;

  const code = String(product_code || product_id || '').trim();
  const deviceUid = String(device_uid || code).trim();
  const parsedStock = Number.parseInt(stock, 10);
  const parsedPrice = Number.parseFloat(price);

  if (!name || !code || !brand || !category || !variant) {
    return res.status(400).json({
      error: 'bad_request',
      message: 'Product name, product ID, brand, category, and variant are required'
    });
  }
  if (!Number.isFinite(parsedPrice) || parsedPrice < 0) {
    return res.status(400).json({ error: 'bad_request', message: 'Valid product price is required' });
  }
  if (!Number.isInteger(parsedStock) || parsedStock < 0) {
    return res.status(400).json({ error: 'bad_request', message: 'Valid stock quantity is required' });
  }

  try {
    const existingProduct = await get(
      'SELECT id FROM products WHERE product_code = $1',
      [code]
    );
    if (existingProduct) {
      return res.status(409).json({
        error: 'product_id_exists',
        message: 'This Product ID is already registered in CRM'
      });
    }

    const existingDevice = await get(
      'SELECT id FROM devices WHERE device_uid = $1',
      [deviceUid]
    );
    if (existingDevice) {
      return res.status(409).json({
        error: 'device_exists',
        message: 'This Device ID is already registered in CRM'
      });
    }

    const newProd = await run(
      `INSERT INTO products
       (name, product_code, description, price, brand, category, variant, stock, valid_until)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
       RETURNING id, name, product_code, description, price, brand, category, variant, stock, valid_until, created_at`,
      [
        name,
        code,
        description || '',
        parsedPrice,
        brand,
        category,
        variant,
        parsedStock,
        valid_until || null
      ]
    );

    const productId = newProd.id;
    const product = newProd.product_code
      ? newProd
      : await get(
          `SELECT id, name, product_code, description, price, brand, category,
                  variant, stock, valid_until, created_at
           FROM products WHERE id = $1`,
          [productId]
        );

    const device = await run(
      `INSERT INTO devices (device_uid, product_id)
       VALUES ($1, $2)
       RETURNING id, device_uid, product_id, registered_at`,
      [deviceUid, productId]
    );

    res.status(201).json({
      message: 'Product created and Product ID is ready for Flutter signup',
      product,
      device
    });
  } catch (err) {
    console.error('[Products] Add error:', err);
    res.status(500).json({ error: 'server_error', message: 'Could not create product' });
  }
}

// Associate a device with a product (admin only)
async function registerDevice(req, res) {
  const { device_uid, product_id } = req.body;
  if (!device_uid || !product_id) return res.status(400).json({ error: 'bad_request', message: 'device_uid and product_id required' });
  try {
    // Verify product exists
    const prod = await get('SELECT id FROM products WHERE id = $1', [product_id]);
    if (!prod) return res.status(404).json({ error: 'product_not_found', message: 'Invalid product_id' });
    // Insert device (or ignore if already exists)
    const existing = await get('SELECT id FROM devices WHERE device_uid = $1', [device_uid]);
    if (existing) return res.status(409).json({ error: 'device_exists', message: 'Device UID already registered' });
    const device = await run(
      `INSERT INTO devices (device_uid, product_id) VALUES ($1, $2) RETURNING id, device_uid, product_id, registered_at`,
      [device_uid, product_id]
    );
    res.status(201).json({ message: 'Device registered', device });
  } catch (err) {
    console.error('[Devices] Register error:', err);
    res.status(500).json({ error: 'server_error', message: 'Could not register device' });
  }
}

// Update a product (admin only)
async function updateProduct(req, res) {
  const { id } = req.params;
  const {
    name,
    description,
    product_code,
    product_id,
    price,
    brand,
    category,
    variant,
    stock,
    valid_until
  } = req.body;

  const code = String(product_code || product_id || '').trim();
  const parsedStock = Number.parseInt(stock, 10);
  const parsedPrice = Number.parseFloat(price);

  if (!name || !code || !brand || !category || !variant) {
    return res.status(400).json({
      error: 'bad_request',
      message: 'Product name, product ID, brand, category, and variant are required'
    });
  }
  if (!Number.isFinite(parsedPrice) || parsedPrice < 0) {
    return res.status(400).json({ error: 'bad_request', message: 'Valid product price is required' });
  }
  if (!Number.isInteger(parsedStock) || parsedStock < 0) {
    return res.status(400).json({ error: 'bad_request', message: 'Valid stock quantity is required' });
  }

  try {
    const existing = await get('SELECT id FROM products WHERE id = $1', [id]);
    if (!existing) {
      return res.status(404).json({ error: 'not_found', message: 'Product not found' });
    }

    // Check if the new product_code already exists for a different product
    const existingCode = await get(
      'SELECT id FROM products WHERE product_code = $1 AND id != $2',
      [code, id]
    );
    if (existingCode) {
      return res.status(409).json({
        error: 'product_id_exists',
        message: 'This Product ID is already used by another product'
      });
    }

    await run(
      `UPDATE products 
       SET name = $1, product_code = $2, description = $3, price = $4, brand = $5, 
           category = $6, variant = $7, stock = $8, valid_until = $9
       WHERE id = $10`,
      [
        name,
        code,
        description || '',
        parsedPrice,
        brand,
        category,
        variant,
        parsedStock,
        valid_until || null,
        id
      ]
    );

    // Get the updated product to return
    const updatedProduct = await get(
      `SELECT id, name, product_code, description, price, brand, category,
              variant, stock, valid_until, created_at
       FROM products WHERE id = $1`,
      [id]
    );

    res.json({ message: 'Product updated successfully', product: updatedProduct });
  } catch (err) {
    console.error('[Products] Update error:', err);
    res.status(500).json({ error: 'server_error', message: 'Could not update product' });
  }
}

// Delete a product (admin only)
async function deleteProduct(req, res) {
  const { id } = req.params;
  try {
    const existing = await get('SELECT id FROM products WHERE id = $1', [id]);
    if (!existing) {
      return res.status(404).json({ error: 'not_found', message: 'Product not found' });
    }
    
    // Note: Devices related to this product will be deleted via ON DELETE CASCADE 
    // or should be handled if foreign keys aren't enabled properly. The schema says ON DELETE CASCADE.
    await run('DELETE FROM products WHERE id = $1', [id]);
    res.json({ message: 'Product deleted successfully' });
  } catch (err) {
    console.error('[Products] Delete error:', err);
    res.status(500).json({ error: 'server_error', message: 'Could not delete product' });
  }
}

module.exports = { listProducts, addProduct, updateProduct, deleteProduct, registerDevice };
