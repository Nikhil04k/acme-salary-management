import api from "./api";

const employeeService = {
  async getEmployees(params = {}) {
    const response = await api.get("/employees", {
      params,
    });

    return response.data;
  },
};

export default employeeService;
