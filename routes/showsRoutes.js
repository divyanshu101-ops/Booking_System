import express from "express";
import store from "../data/store.js";

const router = express.Router();

router.get("/", (req, res) => {
    const { venue } = req.query;

    let filterShow  = store.shows;

    if(venue){
        const targetVenue = venue.trim().toLowerCase();

        filterShow = filterShow.filter(
            (show) => show.venue.toLowerCase() === targetVenue
        );
    }
    res.status(200).json({
        success: true,
        count: filterShow.length,
        data: filterShow,
    });
});

router.get("/:showId", (req, res) => {
    const targetId = parseInt(req.params.showId);

    if(Number.isNaN(targetId)){
        return res.status(400).json({
            success: false,
            error: "Invalid show Id. Id must be an integer",
        })
    }

    const show = store.shows.find((item) => item.id === targetId);

    if(!show){
        return res.status(404).json({
            success: false,
            error: `Show with ID ${targetId} not found.`,
        })
    }

    res.status(200).json({
        success: true,
        data: show,
    });

})

export default router;