import "regenerator-runtime/runtime";

const encodeToBase64 = (file) => {
  return new Promise((resolve, reject) => {
    const reader = new FileReader();
    reader.onloadend = () => resolve(reader.result);
    reader.onerror = reject;
    reader.readAsDataURL(file);
  });
};

const uploadImage = (image) => {
  console.log(checkHealth());
  return encodeToBase64(image)
    .then((encodedImage) => {
      // console.log(encodedImage)
      fetch(process.env.API_ENDPOINT.concat("detect/"), {
        method: "POST",
        body: {
          // image_name: image.name,
          content: encodedImage,
        },
      });
    })
    .then((response) => response.json())
    .catch((error) => console.error(error));
};

const checkHealth = () => {
  return fetch(process.env.API_ENDPOINT.concat("health/"), {
    method: "GET",
  })
    .then((response) => response.json())
    .catch((error) => console.error(error));
};

export { uploadImage };
