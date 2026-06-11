import { useEffect } from 'react';
import { createPortal } from 'react-dom';

/**
 * Modal — renders its children in a portal attached to document.body,
 * completely escaping the sidebar / main-content layout so that
 * position:fixed works correctly regardless of backdrop-filter parents.
 *
 * Usage:
 *   <Modal onClose={() => setOpen(false)}>
 *     <div className="glass-panel modal-content">…</div>
 *   </Modal>
 */
const Modal = ({ children, onClose }) => {
  // Lock body scroll while modal is open
  useEffect(() => {
    const prev = document.body.style.overflow;
    document.body.style.overflow = 'hidden';
    return () => { document.body.style.overflow = prev; };
  }, []);

  // Close on Escape key
  useEffect(() => {
    const handler = (e) => { if (e.key === 'Escape') onClose?.(); };
    document.addEventListener('keydown', handler);
    return () => document.removeEventListener('keydown', handler);
  }, [onClose]);

  return createPortal(
    <div
      className="modal-overlay"
      onMouseDown={(e) => { if (e.target === e.currentTarget) onClose?.(); }}
    >
      {children}
    </div>,
    document.body
  );
};

export default Modal;
