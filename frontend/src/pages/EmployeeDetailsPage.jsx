import { useParams } from 'react-router-dom'

function EmployeeDetailsPage() {
  const { id } = useParams()

  return <h1 className="text-2xl font-bold">Employee Details: {id}</h1>
}

export default EmployeeDetailsPage
