import api from "./api";

const salaryService = {
  async getSalaryHistories(employeeId) {
    const response = await api.get(`/employees/${employeeId}/salary_histories`);
    return response.data.data;
  },

  async createSalary(employeeId, attributes) {
    const response = await api.post(
      `/employees/${employeeId}/salary_histories`,
      { salary_history: attributes },
    );
    return response.data;
  },

  async updateSalary(employeeId, salaryId, attributes) {
    const response = await api.patch(
      `/employees/${employeeId}/salary_histories/${salaryId}`,
      { salary_history: attributes },
    );
    return response.data;
  },

  async cancelSalary(employeeId, salaryId) {
    const response = await api.post(
      `/employees/${employeeId}/salary_histories/${salaryId}/cancel`,
    );
    return response.data;
  },
};

export default salaryService;
