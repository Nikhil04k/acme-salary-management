import api from "./api";

const authService = {
  async login(email, password) {
    const response = await api.post("/login", {
      user: {
        email,
        password,
      },
    });

    const token = response.headers.authorization;

    if (!token) {
      throw new Error("Authentication token was not returned by the server");
    }

    localStorage.setItem("authToken", token);

    return response.data;
  },

  logout() {
    return api.delete("/logout").finally(() => {
      localStorage.removeItem("authToken");
    });
  },
};

export default authService;
