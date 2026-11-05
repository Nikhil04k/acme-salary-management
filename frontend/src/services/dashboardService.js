import api from "./api";

const dashboardService = {
  async getOverview() {
    const response = await api.get("/dashboard/overview");
    return response.data.data;
  },

  async getEmployeeDistribution() {
    const response = await api.get("/dashboard/employee_distribution");
    return response.data.data;
  },

  async getSalaryAnalytics() {
    const response = await api.get("/dashboard/salary_analytics");
    return response.data.data;
  },

  async getRecentSalaryChanges(limit = 8) {
    const response = await api.get("/dashboard/recent_salary_changes", {
      params: { limit },
    });
    return response.data.data;
  },
};

export default dashboardService;
