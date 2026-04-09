const express = require("express");
const productCategories = require("./routes/productCategories");
const products = require("./routes/products");
const cors = require("cors");
const user = require("./routes/users");
const bodyParser = require("body-parser");
const orders = require("./routes/orders");
const app = express();
const PORT = 5004;

app.use(cors());
app.use(bodyParser.json());

app.use("/productCategories", productCategories);
app.use("/products", products);
app.use("/users", user);
app.use("/orders", orders);

const server = app.listen(PORT, () => {
  console.log(`App is running on http://localhost:${PORT}`);
});
