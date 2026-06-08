import { useEffect, useState } from 'react'
import api from '../api/client'

export default function Users() {
  const [users, setUsers]     = useState([])
  const [search, setSearch]   = useState('')
  const [loading, setLoading] = useState(true)

  async function load(q = '') {
    setLoading(true)
    try {
      const { data } = await api.get('/admin/users', { params: { search: q, limit: 100 } })
      setUsers(data.users || [])
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => { load() }, [])

  function handleSearch(e) {
    e.preventDefault()
    load(search)
  }

  return (
    <>
      <div className="page-header">
        <div><h1>👥 Users</h1><p>Registered farmers and users</p></div>
      </div>

      <div className="card">
        <div className="card-header">
          <form onSubmit={handleSearch} style={{ display: 'flex', gap: 8 }}>
            <input
              type="text"
              style={{ width: 240 }}
              placeholder="Search name or username…"
              value={search}
              onChange={e => setSearch(e.target.value)}
            />
            <button type="submit" className="btn btn-primary btn-sm">Search</button>
            {search && <button type="button" className="btn btn-outline btn-sm" onClick={() => { setSearch(''); load('') }}>Clear</button>}
          </form>
          <span className="badge badge-gray">{users.length} users</span>
        </div>
        <div className="table-wrap">
          <table>
            <thead>
              <tr><th>Name</th><th>Username</th><th>Email</th><th>Phone</th><th>Status</th><th>Joined</th></tr>
            </thead>
            <tbody>
              {loading
                ? <tr><td colSpan={6} className="empty-state">Loading…</td></tr>
                : users.length === 0
                  ? <tr><td colSpan={6} className="empty-state"><span>👥</span>No users found</td></tr>
                  : users.map(u => (
                <tr key={u.id}>
                  <td className="fw-600">{u.full_name}</td>
                  <td className="text-muted">@{u.username}</td>
                  <td>{u.email}</td>
                  <td>{u.phone || '—'}</td>
                  <td>
                    <span className={`badge ${u.is_active ? 'badge-green' : 'badge-red'}`}>
                      {u.is_active ? 'Active' : 'Inactive'}
                    </span>
                  </td>
                  <td className="text-muted text-small">{new Date(u.created_at).toLocaleDateString()}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>
    </>
  )
}
