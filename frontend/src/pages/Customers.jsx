import { useEffect, useMemo, useState } from 'react';
import { api } from '../services/api';
import Modal from '../components/Modal';
import {
  CheckCircle,
  Edit3,
  Plus,
  ReceiptText,
  RefreshCw,
  Search,
  Tag,
  Trash2,
  XCircle
} from 'lucide-react';

const emptySaleForm = {
  app_user_id: '',
  customer_name: '',
  product_id: '',
  quantity: '1',
  amount: ''
};

const Customers = () => {
  const [sales, setSales] = useState([]);
  const [appUsers, setAppUsers] = useState([]);
  const [products, setProducts] = useState([]);
  const [loading, setLoading] = useState(true);
  const [searchTerm, setSearchTerm] = useState('');
  const [showSaleModal, setShowSaleModal] = useState(false);
  const [form, setForm] = useState(emptySaleForm);
  const [editingSale, setEditingSale] = useState(null);
  const [notice, setNotice] = useState(null);
  const [formError, setFormError] = useState('');
  const [isSubmitting, setIsSubmitting] = useState(false);

  useEffect(() => {
    fetchData();
  }, []);

  async function fetchData() {
    try {
      setLoading(true);
      const [salesData, usersData, prodData] = await Promise.all([
        api.get('/api/sales'),
        api.get('/api/app-users'),
        api.get('/api/products')
      ]);

      const productList = Array.isArray(prodData) ? prodData : [];
      setSales(Array.isArray(salesData) ? salesData : []);
      setAppUsers(Array.isArray(usersData) ? usersData : []);
      setProducts(productList);

      setForm(prev => {
        if (prev.product_id || productList.length === 0) return prev;
        const firstProduct = productList[0];
        return {
          ...prev,
          product_id: String(firstProduct.id),
          amount: String(Number(firstProduct.price || 0))
        };
      });
    } catch (err) {
      setNotice({ type: 'error', text: err.message || 'Could not load sales records.' });
    } finally {
      setLoading(false);
    }
  }

  const selectedProduct = useMemo(
    () => products.find(product => String(product.id) === String(form.product_id)),
    [form.product_id, products]
  );

  const filteredSales = sales.filter(sale => {
    const text = [
      sale.display_customer_name,
      sale.customer_name,
      sale.customer_username,
      sale.product_name
    ].join(' ').toLowerCase();
    return text.includes(searchTerm.toLowerCase());
  });

  const setField = (key, value) => {
    setForm(prev => ({ ...prev, [key]: value }));
  };

  const setProduct = (productId) => {
    const product = products.find(item => String(item.id) === String(productId));
    const quantity = Number.parseInt(form.quantity, 10) || 1;
    setForm(prev => ({
      ...prev,
      product_id: productId,
      amount: product ? String(Number(product.price || 0) * quantity) : prev.amount
    }));
  };

  const setQuantity = (value) => {
    const quantity = Math.max(1, Number.parseInt(value, 10) || 1);
    setForm(prev => ({
      ...prev,
      quantity: String(quantity),
      amount: selectedProduct ? String(Number(selectedProduct.price || 0) * quantity) : prev.amount
    }));
  };

  const openSaleModal = (sale = null) => {
    const firstProduct = products[0];
    const firstUser = appUsers[0];
    const saleProduct = sale
      ? products.find(product => product.name === sale.product_name)
      : null;

    setForm({
      ...emptySaleForm,
      app_user_id: sale?.app_user_id
        ? String(sale.app_user_id)
        : sale
          ? ''
          : firstUser
            ? String(firstUser.id)
            : '',
      customer_name: sale?.customer_name || sale?.display_customer_name || '',
      product_id: saleProduct
        ? String(saleProduct.id)
        : firstProduct
          ? String(firstProduct.id)
          : '',
      quantity: sale ? String(sale.quantity || 1) : '1',
      amount: sale
        ? String(Number(sale.amount || 0))
        : firstProduct
          ? String(Number(firstProduct.price || 0))
          : ''
    });
    setEditingSale(sale);
    setFormError('');
    setNotice(null);
    setShowSaleModal(true);
  };

  const closeSaleModal = () => {
    setShowSaleModal(false);
    setEditingSale(null);
    setFormError('');
    setIsSubmitting(false);
  };

  const handleSubmitSale = async (event) => {
    event.preventDefault();
    const quantity = Number.parseInt(form.quantity, 10);
    const amount = Number.parseFloat(form.amount);

    if (!selectedProduct) {
      setFormError('Please select a product.');
      return;
    }
    if (!Number.isInteger(quantity) || quantity < 1 || !Number.isFinite(amount) || amount < 0) {
      setFormError('Quantity and sale amount must be valid.');
      return;
    }
    if (!form.app_user_id && !form.customer_name.trim()) {
      setFormError('Please select a Mobile APP user or enter a customer name.');
      return;
    }

    setFormError('');
    setIsSubmitting(true);
    try {
      const payload = {
        app_user_id: form.app_user_id ? Number.parseInt(form.app_user_id, 10) : null,
        customer_name: form.customer_name.trim() || null,
        product_name: selectedProduct.name,
        quantity,
        amount
      };

      if (editingSale) {
        await api.patch(`/api/sales/${editingSale.id}`, payload);
      } else {
        await api.post('/api/sales', payload);
      }
      setNotice({ type: 'success', text: editingSale ? 'Sales record updated successfully.' : 'Sales record saved successfully.' });
      closeSaleModal();
      await fetchData();
    } catch (err) {
      setFormError(err.message || 'Failed to save sales record.');
    } finally {
      setIsSubmitting(false);
    }
  };

  const formatMoney = (value) =>
    `$${Number(value || 0).toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 })}`;

  const deleteSale = async (sale) => {
    const name = sale.display_customer_name || sale.customer_name || sale.customer_username || 'this customer';
    if (!window.confirm(`Delete sale record for ${name}?`)) return;

    try {
      await api.delete(`/api/sales/${sale.id}`);
      setSales(prev => prev.filter(item => item.id !== sale.id));
      setNotice({ type: 'success', text: 'Sales record deleted successfully.' });
    } catch (err) {
      setNotice({ type: 'error', text: err.message || 'Could not delete sales record.' });
    }
  };

  return (
    <div className="slide-in">
      <header style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '32px' }}>
        <div>
          <h1 style={{ fontSize: '28px', fontWeight: 800, color: '#fff', marginBottom: '6px' }}>Sales Records</h1>
          <p style={{ color: 'var(--text-secondary)', fontSize: '15px' }}>Record product sales against authenticated Mobile APP users.</p>
        </div>
        <div style={{ display: 'flex', gap: '10px' }}>
          <button className="glass-btn" onClick={fetchData}>
            <RefreshCw size={16} />
            Refresh
          </button>
          <button className="glass-btn primary" onClick={() => openSaleModal()}>
            <Plus size={18} />
            New Sale
          </button>
        </div>
      </header>

      {notice && (
        <div className={`badge ${notice.type === 'success' ? 'success' : 'danger'}`} style={{ marginBottom: '16px', padding: '10px 12px', borderRadius: '10px' }}>
          {notice.type === 'success' ? <CheckCircle size={14} /> : <XCircle size={14} />}
          {notice.text}
        </div>
      )}

      <div className="glass-panel" style={{ padding: '16px', display: 'flex', gap: '16px', alignItems: 'center', marginBottom: '24px' }}>
        <span style={{ color: 'var(--text-muted)' }}><Search size={20} /></span>
        <input
          type="text"
          placeholder="Search by customer or product..."
          className="glass-input"
          style={{ border: 'none', background: 'transparent', padding: '6px' }}
          value={searchTerm}
          onChange={(event) => setSearchTerm(event.target.value)}
        />
      </div>

      <div className="glass-panel" style={{ padding: '24px' }}>
        {loading ? (
          <div style={{ display: 'flex', justifyContent: 'center', padding: '40px' }}>
            <div style={{ width: '30px', height: '30px', border: '3px solid rgba(255,125,0,0.1)', borderTopColor: 'var(--primary)', borderRadius: '50%', animation: 'spin-slow 1s linear infinite' }} />
          </div>
        ) : (
          <div className="table-container">
            <table className="custom-table">
              <thead>
                <tr>
                  <th>Customer</th>
                  <th>Product</th>
                  <th>Quantity</th>
                  <th>Amount</th>
                  <th>Date</th>
                  <th>Actions</th>
                </tr>
              </thead>
              <tbody>
                {filteredSales.map(sale => (
                  <tr key={sale.id}>
                    <td>
                      <div style={{ fontWeight: 700, color: '#fff' }}>{sale.display_customer_name || sale.customer_name || sale.customer_username || 'Unknown buyer'}</div>
                    </td>
                    <td>{sale.product_name}</td>
                    <td>{sale.quantity}</td>
                    <td><span className="badge info">{formatMoney(sale.amount)}</span></td>
                    <td>{sale.sale_date ? new Date(sale.sale_date).toLocaleDateString() : '-'}</td>
                    <td>
                      <div style={{ display: 'flex', gap: '8px' }}>
                        <button className="glass-btn" onClick={() => openSaleModal(sale)} style={{ padding: '7px 10px' }}>
                          <Edit3 size={14} />
                        </button>
                        <button className="glass-btn danger" onClick={() => deleteSale(sale)} style={{ padding: '7px 10px' }}>
                          <Trash2 size={14} />
                        </button>
                      </div>
                    </td>
                  </tr>
                ))}
                {filteredSales.length === 0 && (
                  <tr>
                    <td colSpan="6" style={{ textAlign: 'center', color: 'var(--text-muted)', padding: '30px' }}>
                      No sales records found.
                    </td>
                  </tr>
                )}
              </tbody>
            </table>
          </div>
        )}
      </div>

      {showSaleModal && (
        <Modal onClose={closeSaleModal}>
          <div className="glass-panel modal-content">
            <div className="modal-header">
              <h3 className="modal-title">{editingSale ? 'Edit Sales Transaction' : 'Record Sales Transaction'}</h3>
              <button className="modal-close" onClick={closeSaleModal}>x</button>
            </div>

            {formError && (
              <div style={{ background: 'rgba(239,68,68,0.15)', border: '1px solid rgba(239,68,68,0.3)', color: '#ef4444', padding: '10px', borderRadius: '8px', fontSize: '13px', marginBottom: '16px', fontWeight: 500 }}>
                {formError}
              </div>
            )}

            <form onSubmit={handleSubmitSale}>
              <div className="form-group">
                <label>Mobile APP User</label>
                <select className="glass-input" value={form.app_user_id} onChange={(event) => setField('app_user_id', event.target.value)}>
                  <option value="">No app user</option>
                  {appUsers.map(user => (
                    <option key={user.id} value={user.id}>{user.username}</option>
                  ))}
                </select>
              </div>

              <div className="form-group">
                <label>Customer Name</label>
                <input
                  className="glass-input"
                  value={form.customer_name}
                  onChange={(event) => setField('customer_name', event.target.value)}
                  placeholder="Write customer name manually"
                />
              </div>

              <div className="form-group">
                <label>Product</label>
                <select className="glass-input" value={form.product_id} onChange={(event) => setProduct(event.target.value)}>
                  <option value="">Select product...</option>
                  {products.map(product => (
                    <option key={product.id} value={product.id}>{product.name} ({formatMoney(product.price)})</option>
                  ))}
                </select>
              </div>

              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '16px' }}>
                <div className="form-group">
                  <label>Quantity</label>
                  <input className="glass-input" type="number" min="1" value={form.quantity} onChange={(event) => setQuantity(event.target.value)} />
                </div>
                <div className="form-group">
                  <label>Sale Amount</label>
                  <div style={{ position: 'relative' }}>
                    <span style={{ position: 'absolute', left: '12px', top: '12px', color: 'var(--text-muted)' }}><Tag size={16} /></span>
                    <input className="glass-input" type="number" min="0" step="0.01" style={{ paddingLeft: '40px' }} value={form.amount} onChange={(event) => setField('amount', event.target.value)} />
                  </div>
                </div>
              </div>

              <button type="submit" className="glass-btn primary" style={{ width: '100%', justifyContent: 'center' }} disabled={isSubmitting}>
                {isSubmitting ? 'Saving Sales Record...' : (
                  <>
                    <ReceiptText size={16} />
                    {editingSale ? 'Update Sales Record' : 'Save Sales Record'}
                  </>
                )}
              </button>
            </form>
          </div>
        </Modal>
      )}
    </div>
  );
};

export default Customers;
