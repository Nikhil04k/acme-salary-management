function StatCard({ title, value, description, color }) {
  const colors = {
    blue: 'bg-blue-50 text-blue-600',
    green: 'bg-green-50 text-green-600',
    orange: 'bg-orange-50 text-orange-600',
    red: 'bg-red-50 text-red-600',
  }

  return (
    <div className="rounded-xl border border-slate-200 bg-white p-6 shadow-sm">
      <p className="text-sm font-medium text-slate-500">
        {title}
      </p>

      <h3 className="mt-3 text-3xl font-bold text-slate-800">
        {Number(value).toLocaleString('en-IN')}
      </h3>

      <span className={`mt-3 inline-block rounded-md px-2 py-1 text-xs font-medium ${colors[color]}`}>
        {description}
      </span>
    </div>
  )
}

export default StatCard
