import "regenerator-runtime/runtime";

const encodeToBase64 = async (file) => {
  return new Promise((resolve, reject) => {
    const reader = new FileReader();
    reader.onloadend = () => resolve(reader.result);
    reader.onerror = reject;
    reader.readAsDataURL(file);
  });
};

/**
 *
 * @param {file} image
 * @returns the results of the image upload
 */
const uploadImage = async (image) => {
  console.log(checkHealth());
  try {
    const encodedImage = (await encodeToBase64(image)).split(",")[1];
    const payload = JSON.stringify({
      image_name: image.name,
      content: encodedImage,
    });
    let res = await fetch(process.env.API_ENDPOINT.concat("upload"), {
      method: "PUT",
      body: payload,
    });
    res = await res.json();
    return res;
  } catch (error) {
    console.error(error);
  }
};

/**
 *
 * @param {file} image
 * @returns the results of the image detection
 */
const detectImage = async (image) => {
  console.log(checkHealth());

  try {
    const encodedImage = (await encodeToBase64(image)).split(",")[1];
    const payload = JSON.stringify({
      content: encodedImage,
    });
    let res = await fetch(process.env.API_ENDPOINT.concat("detect"), {
      method: "POST",
      body: payload,
    });
    res = await res.json();
    return res;
  } catch (error) {
    console.error(error);
  }
};

/**
 *
 * @param {string} url, the S3 url of the image
 * @returns the results of the image deletion
 */
const deleteAnImage = async (url) => {
  console.log(checkHealth());

  try {
    const payload = JSON.stringify({
      url: url,
    });
    let res = await fetch(process.env.API_ENDPOINT.concat("delete"), {
      method: "POST",
      body: payload,
    });
    res = await res.json();
    return res;
  } catch (error) {
    console.error(error);
  }
};

/**
 *
 * @param {string} url, the S3 url of the image
 * @param {string[]} tags the tags associated with the image
 * @returns the results of the image tag removal, which are S3 urls of the images with the given tags
 */
const removeATag = async (url, tags) => {
  console.log(checkHealth());

  try {
    const payload = JSON.stringify({
      url: url,
      tags: tags,
    });
    let res = await fetch(process.env.API_ENDPOINT.concat("remove"), {
      method: "POST",
      body: payload,
    });
    res = await res.json();
    return res;
  } catch (error) {
    console.error(error);
  }
};

/**
 *
 * @param {string[]} tags the tags associated with the images
 * @returns the results of the image search, which are S3 urls of the images with the given tags
 */
const searchForImage = async (tags) => {
  console.log(checkHealth());

  try {
    const payload = JSON.stringify({
      tags: tags,
    });
    let res = await fetch(process.env.API_ENDPOINT.concat("search"), {
      method: "POST",
      body: payload,
    });
    res = await res.json();
    return res;
  } catch (error) {
    console.error(error);
  }
};

/**
 * Check if the server is up and running
 * @returns {boolean} true if the server is up and running
 * @throws {Error} if the server is down
 */
const checkHealth = async () => {
  try {
    const res = await fetch(process.env.API_ENDPOINT.concat("health"), {
      method: "GET",
    });
    console.log(res.ok);
    return res.ok;
  } catch (error) {
    console.error(error);
  }
};
export {
  uploadImage,
  detectImage,
  searchForImage,
  checkHealth,
  removeATag,
  deleteAnImage,
};
