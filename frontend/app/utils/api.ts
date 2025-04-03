import axios from "axios";

const backendApi = "http://170.106.106.90:8001";

const newApi = {
  getNews: async () => {
    return axios.get(`${backendApi}/news`).then((response) => {
      if (response.status === 200) {
        return response.data;
      } else {
        throw Error("Failed to get news.");
      }
    });
  },
  getNewsById: async (id: string) => {
    return axios.get(`${backendApi}/news/${id}`).then((response) => {
      if (response.status === 200) {
        return response.data;
      } else {
        throw Error("Failed to get news.");
      }
    });
  },
  updateNews: async (id: string, data: any) => {
    return axios.put(`${backendApi}/news/${id}`, data).then((response) => {
      if (response.status === 200) {
        return response.data;
      } else {
        throw Error("Failed to update news.");
      }
    });
  },
};

const defaultExport = {
  ...newApi,
};

export default defaultExport;
