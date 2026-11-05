import api from "./api";

const referenceDataService = {
  async getCountries() {
    const response = await api.get("/countries");
    return response.data.data;
  },

  async getDepartments() {
    const response = await api.get("/departments");
    return response.data.data;
  },

  async getJobTitles() {
    const response = await api.get("/job_titles");
    return response.data.data;
  },
};

export default referenceDataService;
