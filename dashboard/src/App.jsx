import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom'
import Login from './pages/Login'
import Layout from './components/Layout'
import Overview from './pages/Overview'
import Users from './pages/Users'
import Diseases from './pages/Diseases'
import Pesticides from './pages/Pesticides'
import Activities from './pages/Activities'
import ModelConfig from './pages/ModelConfig'
import Diagnose from './pages/Diagnose'

function PrivateRoute({ children }) {
  return localStorage.getItem('adminToken')
    ? children
    : <Navigate to="/login" replace />
}

export default function App() {
  return (
    <BrowserRouter>
      <Routes>
        <Route path="/login" element={<Login />} />
        <Route path="/" element={<PrivateRoute><Layout /></PrivateRoute>}>
          <Route index element={<Overview />} />
          <Route path="users" element={<Users />} />
          <Route path="diseases" element={<Diseases />} />
          <Route path="pesticides" element={<Pesticides />} />
          <Route path="activities" element={<Activities />} />
          <Route path="model" element={<ModelConfig />} />
          <Route path="diagnose" element={<Diagnose />} />
        </Route>
        <Route path="*" element={<Navigate to="/" replace />} />
      </Routes>
    </BrowserRouter>
  )
}
