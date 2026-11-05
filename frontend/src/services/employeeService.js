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

  async createEmployee(employeeData) {
    const response = await api.post("/employees", {
      employee: employeeData,
    });

    return response.data;
  },

  async updateEmployee(id, employeeData) {
    const response = await api.patch(`/employees/${id}`, {
      employee: employeeData,
    });

    return response.data;
  },

  async exportEmployees(params = {}) {
    const response = await api.get("/employees/export", {
      params,
      responseType: "blob",
    });

    return response.data;
  },

  async importEmployees(file) {
    const formData = new FormData();
    formData.append("file", file);

    const response = await api.post("/employees/import", formData);

    return response.data;
  },
};

export default employeeService;
