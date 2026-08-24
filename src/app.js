import express from "express";
import showsRouter from "../routes/showsRoutes.js";
const app = express();

// Simple observability middleware
app.use((req, res, next) => {
    console.log(`Incoming request: ${req.method} ${req.url}`);
    next(); // Pass control to the next handler
});

app.use("/shows", showsRouter);

export default app;