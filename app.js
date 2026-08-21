import express from "express";
import showsRouter from "./routes/showsRoutes.js";
const port = 3000;
const app = express();

// Simple observability middleware
app.use((req, res, next) => {
    console.log(`Incoming request: ${req.method} ${req.url}`);
    next(); // Pass control to the next handler
});

app.use("/shows", showsRouter);

app.listen(port, () => {
    console.log(`Server running on port ${port}`);
});