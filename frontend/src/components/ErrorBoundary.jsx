import React from 'react';

class ErrorBoundary extends React.Component {
  constructor(props) {
    super(props);
    this.state = { hasError: false, error: null };
  }

  static getDerivedStateFromError(error) {
    return { hasError: true, error };
  }

  componentDidCatch(error, errorInfo) {
    console.error('[ErrorBoundary] Caught:', error, errorInfo);
  }

  render() {
    if (this.state.hasError) {
      return (
        <div style={{
          padding: '40px',
          display: 'flex',
          flexDirection: 'column',
          alignItems: 'center',
          justifyContent: 'center',
          gap: '16px',
          minHeight: '300px',
        }}>
          <div className="glass-panel" style={{
            padding: '30px 40px',
            textAlign: 'center',
            maxWidth: '500px',
          }}>
            <h3 style={{ color: '#ef4444', fontSize: '18px', fontWeight: 700, marginBottom: '12px' }}>
              Something went wrong
            </h3>
            <p style={{ color: 'hsl(var(--text-secondary))', fontSize: '14px', lineHeight: '1.6', marginBottom: '16px' }}>
              {this.state.error?.message || 'An unexpected error occurred in this section.'}
            </p>
            <button
              className="glass-btn primary"
              onClick={() => this.setState({ hasError: false, error: null })}
              style={{ justifyContent: 'center' }}
            >
              Try Again
            </button>
          </div>
        </div>
      );
    }

    return this.props.children;
  }
}

export default ErrorBoundary;
