/* eslint-disable react-hooks/set-state-in-effect */
import { useCallback, useEffect, useState } from 'react';
import { api } from '../services/api';
import {
  Boxes,
  CheckCircle,
  Plus,
  QrCode,
  RefreshCw,
  XCircle,
  Pencil,
  Trash2
} from 'lucide-react';

const initialForm = {
  name: '',
  description: '',
  product_id: '',
  price: '',
  brand: '',
  category: '',
  variant: '',
  stock: '1'
};

const Products = () => {
  const [products, setProducts] = useState([]);
  const [form, setForm] = useState(initialForm);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [notice, setNotice] = useState(null);
  const [editId, setEditId] = useState(null);

  const fetchProducts = useCallback(() => {
    setLoading(true);
    api.get('/api/products')
      .then(data => setProducts(Array.isArray(data) ? data : []))
      .catch(err => setNotice({ type: 'error', text: err.message }))
      .finally(() => setLoading(false));
  }, []);

  useEffect(() => { fetchProducts(); }, [fetchProducts]);

  const setField = (key, value) => {
    setForm(prev => ({ ...prev, [key]: value }));
  };

  const submit = async (event) => {
    event.preventDefault();
    setSaving(true);
    setNotice(null);
    try {
      const payload = {
        ...form,
        price: Number(form.price),
        stock: Number.parseInt(form.stock, 10)
      };

      if (editId) {
        await api.put(`/api/products/${editId}`, payload);
        setNotice({
          type: 'success',
          text: 'Product updated successfully.'
        });
      } else {
        await api.post('/api/products', payload);
        setNotice({
          type: 'success',
          text: 'Product added successfully. The Product ID is now active and ready for use.'
        });
      }
      
      setForm(initialForm);
      setEditId(null);
      fetchProducts();
    } catch (err) {
      setNotice({ type: 'error', text: err.message });
    } finally {
      setSaving(false);
    }
  };

  const handleEdit = (product) => {
    setEditId(product.id);
    setForm({
      name: product.name || '',
      description: product.description || '',
      product_id: product.product_code || '',
      price: product.price || '',
      brand: product.brand || '',
      category: product.category || '',
      variant: product.variant || '',
      stock: product.stock !== undefined ? product.stock.toString() : '1'
    });
    window.scrollTo({ top: 0, behavior: 'smooth' });
  };

  const handleDelete = async (id) => {
    if (!window.confirm('Are you sure you want to delete this product?')) return;
    try {
      await api.delete(`/api/products/${id}`);
      setNotice({ type: 'success', text: 'Product deleted successfully.' });
      fetchProducts();
    } catch (err) {
      setNotice({ type: 'error', text: err.message });
    }
  };

  const cancelEdit = () => {
    setEditId(null);
    setForm(initialForm);
  };

  return (
    <div className="slide-in">
      <header style={{ marginBottom: '28px' }}>
        <h1 style={{ fontSize: '26px', fontWeight: 800, color: '#fff', marginBottom: '4px', display: 'flex', alignItems: 'center', gap: '10px' }}>
          <Boxes size={24} color="hsl(var(--primary))" /> Products
        </h1>
        <p style={{ color: 'hsl(var(--text-secondary))', fontSize: '14px' }}>
          Manage your product inventory and product catalog.
        </p>
      </header>

      <section className="glass-panel" style={{ padding: '24px', marginBottom: '22px' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: '10px', marginBottom: '18px' }}>
          {editId ? <Pencil size={18} color="hsl(var(--primary))" /> : <Plus size={18} color="hsl(var(--primary))" />}
          <h2 style={{ color: '#fff', fontSize: '18px', fontWeight: 800 }}>{editId ? 'Edit Product' : 'Add Product'}</h2>
        </div>

        {notice && (
          <div className={`badge ${notice.type === 'success' ? 'success' : 'danger'}`} style={{ marginBottom: '16px', padding: '10px 12px', borderRadius: '10px' }}>
            {notice.type === 'success' ? <CheckCircle size={14} /> : <XCircle size={14} />}
            {notice.text}
          </div>
        )}

        <form onSubmit={submit}>
          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4, minmax(0, 1fr))', gap: '14px' }}>
            <label>
              <span>Product Name</span>
              <input className="glass-input" value={form.name} onChange={e => setField('name', e.target.value)} required />
            </label>
            <label>
              <span>Product ID</span>
              <input className="glass-input" value={form.product_id} onChange={e => setField('product_id', e.target.value)} required />
            </label>
            <label>
              <span>Price</span>
              <input className="glass-input" type="number" min="0" step="0.01" value={form.price} onChange={e => setField('price', e.target.value)} required />
            </label>
            <label>
              <span>Brand</span>
              <input className="glass-input" value={form.brand} onChange={e => setField('brand', e.target.value)} required />
            </label>
            <label>
              <span>Category</span>
              <input className="glass-input" value={form.category} onChange={e => setField('category', e.target.value)} required />
            </label>
            <label>
              <span>Variant</span>
              <input className="glass-input" value={form.variant} onChange={e => setField('variant', e.target.value)} required />
            </label>
            <label>
              <span>Stock</span>
              <input className="glass-input" type="number" min="0" value={form.stock} onChange={e => setField('stock', e.target.value)} required />
            </label>
          </div>

          <label style={{ display: 'block', marginTop: '14px' }}>
            <span>Description</span>
            <textarea className="glass-input" rows="3" value={form.description} onChange={e => setField('description', e.target.value)} style={{ resize: 'vertical' }} />
          </label>

          <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '10px', marginTop: '18px' }}>
            {editId && (
              <button type="button" className="glass-btn" onClick={cancelEdit}>
                Cancel Edit
              </button>
            )}
            {!editId && (
              <button type="button" className="glass-btn" onClick={fetchProducts}>
                <RefreshCw size={15} /> Refresh
              </button>
            )}
            <button type="submit" className="glass-btn primary" disabled={saving}>
              {editId ? <Pencil size={15} /> : <Plus size={15} />} 
              {saving ? 'Saving...' : editId ? 'Save Changes' : 'Add Product'}
            </button>
          </div>
        </form>
      </section>

      <section className="glass-panel" style={{ padding: '24px' }}>
        {loading ? (
          <div style={{ display: 'flex', justifyContent: 'center', padding: '40px' }}>
            <div style={{ width: '30px', height: '30px', border: '3px solid rgba(255,125,0,.1)', borderTopColor: 'hsl(var(--primary))', borderRadius: '50%', animation: 'spin-slow 1s linear infinite' }} />
          </div>
        ) : (
          <div className="table-container">
            <table className="custom-table">
              <thead>
                <tr>
                  <th>Product</th>
                  <th>Product ID</th>
                  <th>Brand</th>
                  <th>Category</th>
                  <th>Variant</th>
                  <th>Price</th>
                  <th>Stock</th>
                  <th style={{ textAlign: 'right' }}>Actions</th>
                </tr>
              </thead>
              <tbody>
                {products.map(product => {
                  return (
                    <tr key={product.id}>
                      <td>
                        <div style={{ fontWeight: 700, color: '#fff' }}>{product.name}</div>
                        <div style={{ color: 'hsl(var(--text-muted))', fontSize: '11px' }}>{product.description || 'No description'}</div>
                      </td>
                      <td><span className="badge info"><QrCode size={10} />{product.product_code}</span></td>
                      <td>{product.brand}</td>
                      <td>{product.category}</td>
                      <td>{product.variant}</td>
                      <td>${Number(product.price || 0).toLocaleString()}</td>
                      <td><span className={Number(product.stock || 0) > 0 ? 'badge success' : 'badge danger'}>{product.stock}</span></td>
                      <td style={{ textAlign: 'right' }}>
                        <div style={{ display: 'flex', gap: '6px', justifyContent: 'flex-end' }}>
                          <button className="glass-btn" style={{ padding: '5px 10px' }} onClick={() => handleEdit(product)}>
                            <Pencil size={13} />
                          </button>
                          <button className="glass-btn danger" style={{ padding: '5px 10px' }} onClick={() => handleDelete(product.id)}>
                            <Trash2 size={13} />
                          </button>
                        </div>
                      </td>
                    </tr>
                  );
                })}
                {products.length === 0 && (
                  <tr>
                    <td colSpan="8" style={{ textAlign: 'center', color: 'hsl(var(--text-muted))', padding: '30px' }}>
                      No products added yet
                    </td>
                  </tr>
                )}
              </tbody>
            </table>
          </div>
        )}
      </section>
    </div>
  );
};

export default Products;
