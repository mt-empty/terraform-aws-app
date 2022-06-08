import "regenerator-runtime/runtime";

const encodeToBase64 = async (file) => {
  return new Promise((resolve, reject) => {
    const reader = new FileReader();
    reader.onloadend = () => resolve(reader.result);
    reader.onerror = reject;
    reader.readAsDataURL(file);
  });
};

const uploadImage = async (image) => {
  console.log(checkHealth());
  const encodedImage = (await encodeToBase64(image)).split(",")[1];
  const payload = JSON.stringify({
    image_name: image.name,
    content: encodedImage,
  });
  fetch(process.env.API_ENDPOINT.concat("upload"), {
    method: "PUT",
    body: payload,
  })
    .then((res) => res.json())
    .then(console.log)
    .catch((error) => console.error(error));
};

const detectImage = async (image) => {
  console.log(checkHealth());
  const encodedImage = (await encodeToBase64(image)).split(",")[1];

  const payload = JSON.stringify({
    content: encodedImage,
  });

  fetch(process.env.API_ENDPOINT.concat("detect"), {
    method: "POST",
    body: payload,
  })
    .then((res) => res.json())
    .then(console.log)
    .catch((error) => console.error(error));
};

const deleteAnImage = async (image) => {
  console.log(checkHealth());

  fetch(process.env.API_ENDPOINT.concat("delete"), {
    method: "POST",
    body: {
      url: url,
    },
  })
    .then((res) => res.json())
    .then(console.log)
    .catch((error) => console.error(error));
};

const removeATag = async (url, tags) => {
  console.log(checkHealth());

  fetch(process.env.API_ENDPOINT.concat("remove"), {
    method: "POST",
    body: {
      url: url,
      tags: tags,
    },
  })
    .then((res) => res.json())
    .then(console.log)
    .catch((error) => console.error(error));
};

const searchForImage = async (tags) => {
  console.log(checkHealth());

  fetch(process.env.API_ENDPOINT.concat("search"), {
    method: "POST",
    body: {
      tags: tags,
    },
  })
    .then((res) => res.json())
    .then(console.log)
    .catch((error) => console.error(error));
};

const checkHealth = async () => {
  try {
    const res = await fetch(process.env.API_ENDPOINT.concat("health"), {
      method: "GET",
    });
    const message = await res.json();
    return console.log(message);
  } catch (error) {
    return console.error(error);
  }
};
export { uploadImage, detectImage, searchForImage, checkHealth, removeATag, deleteAnImage };
