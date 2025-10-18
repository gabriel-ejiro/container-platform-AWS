import express from "express";
const app = express();
const PORT = process.env.PORT || 3000;

app.get("/", (_req, res) => {
  res.send("Hello from ECS on EC2 + ALB + GitHub OIDC! 🚀");
});

app.get("/health", (_req, res) => res.status(200).send("ok"));

app.listen(PORT, () => {
  console.log(`Server listening on ${PORT}`);
});
