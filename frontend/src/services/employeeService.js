import api from "./api";

const employeeService = {
  async getEmployees(params = {}) {
    const response = await api.get("/employees", { params });
    return response.data;
  },

  async getEmployee(id) {
    const response = await api.get(`/employees/${id}`);
    return response.data.data;
  },
};

export default employeeService;
