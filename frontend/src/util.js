import "regenerator-runtime/runtime";

const encodeToBase64 = (file) => {
  return new Promise((resolve, reject) => {
    const reader = new FileReader();
    reader.onloadend = () => resolve(reader.result);
    reader.onerror = reject;
    reader.readAsDataURL(file);
  });
};

const checkHealth = () => {
  return fetch(process.env.API_ENDPOINT.concat("health/"), {
    method: "GET",
  })
    .then((response) => response.json())
    .catch((error) => console.error(error));
};

const uploadImage = (image) => {
  console.log(checkHealth());
  return encodeToBase64(image)
    .then((encodedImage) => {
      // console.log(encodedImage)
      fetch(process.env.API_ENDPOINT.concat("upload/"), {
        method: "PUT",
        body: {
          image_name: image.name,
          content: encodedImage,
        },
      });
    })
    .then((response) => response.json())
    .catch((error) => console.error(error));
};

const detectImage = (image) => {
  return encodeToBase64(image)
    .then((encodedImage) => {
      // console.log(encodedImage)
      fetch(process.env.API_ENDPOINT.concat("detect/"), {
        method: "POST",
        body: {
          content: encodedImage,
        },
      });
    })
    .then((response) => response.json())
    .catch((error) => console.error(error));
};

const searchForImage = (tags) => {
  return fetch(process.env.API_ENDPOINT.concat("search/"), {
    method: "POST",
    body: {
      tags: tags,
    },
  })
    .then((response) => response.json())
    .catch((error) => console.error(error));
};

const removeATag = (tags, url) => {
  return fetch(process.env.API_ENDPOINT.concat("remove/"), {
    method: "POST",
    body: {
      url: url,
      tags: tags,
    },
  })
    .then((response) => response.json())
    .catch((error) => console.error(error));
};

const deleteAnImage = (url) => {
  return fetch(process.env.API_ENDPOINT.concat("delete/"), {
    method: "POST",
    body: {
      url: url,
    },
  })
    .then((response) => response.json())
    .catch((error) => console.error(error));
};

export { uploadImage, detectImage, searchForImage, checkHealth, removeATag, deleteAnImage };
