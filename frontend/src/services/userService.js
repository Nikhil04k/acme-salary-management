import api from "./api";

const userService = {
  async getCurrentUser() {
    const response = await api.get("/me");
    return response.data.data;
  },
};

export default userService;
