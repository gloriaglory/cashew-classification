import { useEffect, useState } from 'react'
import api from '../api/client'

const EMPTY = { disease: '', pesticide_name: '', dosage: '', application_method: '', recommendation: '' }

export default function Pesticides() {
  const [pesticides, setPesticides] = useState([])
  const [diseases, setDiseases]     = useState([])
  const [showModal, setShowModal]   = useState(false)
  const [form, setForm]             = useState(EMPTY)
  const [saving, setSaving]         = useState(false)

  async function load() {
    const [p, d] = await Promise.all([api.get('/admin/pesticides'), api.get('/admin/diseases')])
    setPesticides(p.data.pesticides || [])
    setDiseases(d.data.diseases || [])
  }

  useEffect(() => { load() }, [])

  async function handleAdd(e) {
    e.preventDefault()
    setSaving(true)
    try {
      await api.post('/admin/add-pesticide', { ...form, disease_id: form.disease })
      setShowModal(false)
      setForm(EMPTY)
      load()
    } finally {
      setSaving(false)
    }
  }

  async function handleDelete(id) {
    if (!confirm('Delete this pesticide record?')) return
    await api.delete(`/admin/delete-pesticide/${id}`)
    load()
  }

  return (
    <>
      <div className="page-header">
        <div><h1>💧 Pesticides</h1><p>Treatment recommendations per disease</p></div>
        <button className="btn btn-primary" onClick={() => { setForm(EMPTY); setShowModal(true) }}>+ Add Pesticide</button>
      </div>

      <div className="card">
        <div className="table-wrap">
          <table>
            <thead><tr><th>Disease</th><th>Pesticide</th><th>Dosage</th><th>Application</th><th></th></tr></thead>
            <tbody>
              {pesticides.length === 0
                ? <tr><td colSpan={5} className="empty-state"><span>💧</span>No pesticides yet</td></tr>
                : pesticides.map(p => (
                <tr key={p.id}>
                  <td><span className="badge badge-green">{p.disease_name}</span></td>
                  <td className="fw-600">{p.pesticide_name}</td>
                  <td className="text-muted text-small">{p.dosage?.slice(0, 50)}</td>
                  <td className="text-muted text-small">{p.application_method?.slice(0, 55)}</td>
                  <td><button className="btn btn-danger btn-sm" onClick={() => handleDelete(p.id)}>🗑</button></td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>

      {showModal && (
        <div className="modal-overlay" onClick={() => setShowModal(false)}>
          <div className="modal" onClick={e => e.stopPropagation()}>
            <div className="modal-header">
              <h3>Add Pesticide</h3>
              <button className="modal-close" onClick={() => setShowModal(false)}>×</button>
            </div>
            <form onSubmit={handleAdd}>
              <div className="modal-body">
                <div className="form-group">
                  <label>Disease</label>
                  <select value={form.disease} onChange={e => setForm(f => ({ ...f, disease: e.target.value }))} required>
                    <option value="">Select disease…</option>
                    {diseases.map(d => <option key={d.id} value={d.id}>{d.disease_name}</option>)}
                  </select>
                </div>
                <div className="form-group"><label>Pesticide Name</label><input value={form.pesticide_name} onChange={e => setForm(f => ({ ...f, pesticide_name: e.target.value }))} required /></div>
                <div className="form-group"><label>Dosage</label><input value={form.dosage} onChange={e => setForm(f => ({ ...f, dosage: e.target.value }))} required /></div>
                <div className="form-group"><label>Application Method</label><textarea value={form.application_method} onChange={e => setForm(f => ({ ...f, application_method: e.target.value }))} required /></div>
                <div className="form-group"><label>Recommendation</label><textarea value={form.recommendation} onChange={e => setForm(f => ({ ...f, recommendation: e.target.value }))} required /></div>
              </div>
              <div className="modal-footer">
                <button type="button" className="btn btn-outline" onClick={() => setShowModal(false)}>Cancel</button>
                <button type="submit" className="btn btn-primary" disabled={saving}>{saving ? 'Saving…' : 'Save'}</button>
              </div>
            </form>
          </div>
        </div>
      )}
    </>
  )
}
