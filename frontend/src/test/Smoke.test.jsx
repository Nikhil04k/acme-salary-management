import { render, screen } from '@testing-library/react'

function TestComponent() {
  return <h1>ACME Salary Management System</h1>
}

describe('Vitest configuration', () => {
  it('renders a React component successfully', () => {
    render(<TestComponent />)

    expect(
      screen.getByText('ACME Salary Management System')
    ).toBeInTheDocument()
  })
})
