const express = require("express");
const cors = require("cors");
const mysql = require("mysql");

const app = express();
app.use(express.json());
app.use(cors());

const db = mysql.createConnection({
    host: "localhost",
    user: "root",
    password: "",
    database: "blood_donation"
});

db.connect(err => {
    if (err) throw err;
    console.log("Database Connected");
});

// Validation function for donor registration
const validateDonorData = (data) => {
    const { name, contact, bloodGroup, location } = data;
    const errors = [];

    // Name validation
    if (!name || name.length < 2) errors.push("Invalid name");

    // Contact validation
    if (!contact || !/^\d{10}$/.test(contact)) errors.push("Invalid contact number");

    // Blood group validation
    const validBloodGroups = ["A+", "A-", "B+", "B-", "O+", "O-", "AB+", "AB-"];
    if (!bloodGroup || !validBloodGroups.includes(bloodGroup.toUpperCase())) {
        errors.push("Invalid blood group");
    }

    // Location validation
    if (!location || location.length < 2) errors.push("Invalid location");

    return errors;
};

// Hospital Verification Route
app.post("/verify-hospital", (req, res) => {
    const { name, location, contact } = req.body;
    const query = "INSERT INTO hospitals (name, location, contact, verified) VALUES (?, ?, ?, ?)";
    
    db.query(query, [name, location, contact, true], (err, result) => {
        if (err) {
            console.error("Hospital Verification Error:", err);
            return res.status(500).json({ 
                message: "Hospital verification failed", 
                error: err.message 
            });
        }
        res.status(201).json({ 
            message: "Hospital Verified Successfully", 
            hospitalId: result.insertId 
        });
});
});

// New Route to Get Hospital Details
app.get("/hospital-details", (req, res) => {
    const query = "SELECT name, location, contact FROM hospitals WHERE verified = true";
    
    db.query(query, (err, results) => {
        if (err) {
            console.error("Hospital Details Retrieval Error:", err);
            return res.status(500).json({ 
                message: "Could not retrieve hospital details", 
                error: err.message 
            });
        }
        res.status(200).json(results);
    });
});

// Registration Route with Enhanced Validation
app.post("/register", (req, res) => {
    const validationErrors = validateDonorData(req.body);
    
    if (validationErrors.length > 0) {
        return res.status(400).json({ 
            message: "Registration failed", 
            errors: validationErrors 
        });
    }

    const { name, contact, bloodGroup, location } = req.body;
    const query = "INSERT INTO donors (name, contact, blood_group, location) VALUES (?, ?, ?, ?)";
    
    db.query(query, [name, contact, bloodGroup, location], (err, result) => {
        if (err) {
            console.error("Registration Error:", err);
            return res.status(500).json({ 
                message: "Internal server error", 
                error: err.message 
            });
        }
        res.status(201).json({ 
            message: "Donor Registered Successfully", 
            donorId: result.insertId 
        });
    });
});

// Chatbot Route with Hospital Verification
app.post("/chatbot", (req, res) => {
    const query = req.body.query.toLowerCase().trim();
    const hospitalDetails = req.body.hospitalDetails;

    // Predefined responses
    const generalResponses = {
        "hi": "Hello! How can I assist you with blood donation?",
        "hello": "Hi there! Need help finding a blood donor?",
        "is blood donation safe?" : "Blood donation centers use new, sterile needles and equipment for each donor, eliminating the risk of contracting bloodborne infections.It can save lives by helping individuals in need of blood transfusions.",
        "is blood donation  good?":"Blood donation centers use new, sterile needles and equipment for each donor, eliminating the risk of contracting bloodborne infections.It can save lives by helping individuals in need of blood transfusions.",
        "help": "I can help you find blood donors. Try searching by blood group and location, like 'A+, Chennai'.",
        "how to donate blood?": "To donate blood, visit your nearest blood bank or hospital. Ensure you're healthy and eligible.",
        "who can donate blood?": "Generally, healthy adults aged 18-65 can donate blood. Specific conditions may vary.",
        "how often can i donate blood?": "Typically, whole blood can be donated every 3-4 months. Consult local guidelines.",
        "is blood donation safe?": "Yes, blood donation is safe. Sterile, single-use equipment is always used.",
        "hospital details": "Use 'Get Hospital Details' option in the chatbot to view verified hospital information.",
        "thank you":"You're very welcome!"
    };

    // Check for predefined responses
    if (generalResponses[query]) {
        return res.json({ reply: generalResponses[query] });
    }

    // Get Hospital Details request
    if (query === "get hospital details") {
        const query = "SELECT name, location, contact FROM hospitals WHERE verified = true";
        
        db.query(query, (err, results) => {
            if (err) {
                console.error("Hospital Details Retrieval Error:", err);
                return res.status(500).json({ 
                    reply: "Could not retrieve hospital details." 
                });
            }

            if (results.length > 0) {
                let responseText = "Verified Hospitals:<br>";
                results.forEach(hospital => {
                    responseText += `Name : ${hospital.name}\n - Location : ${hospital.location}\n - Contact : ${hospital.contact}<br><br>`;
                });
                res.json({ reply: responseText, bypassVerification: true });
            } else {
                res.json({ reply: "No verified hospitals found.", bypassVerification: true });
            }
        });
        return;
    }

    // Require hospital details for donor searches
    const bloodGroupLocationMatch = query.match(/^(a|b|o|ab)[+-],\s*[a-z\s]+$/);
    const locationOnlyMatch = query.match(/^[a-z\s]+$/);

    // Validate hospital details for donor searches
    const validateHospitalDetails = (details) => {
        if (!details) return false;
        const { name, location, contact } = details;
        return name && name.trim().length >= 2 &&
               location && location.trim().length >= 2 &&
               contact && /^\d{10}$/.test(contact);
    };

    // Donor search logic
    let sql = "";
    let params = [];

    try {
        if (bloodGroupLocationMatch) {
            const [bloodGroup, location] = query.split(",");
            sql = "SELECT name, contact, location, blood_group FROM donors WHERE UPPER(blood_group) = ? AND LOWER(location) = ?";
            params = [bloodGroup.trim().toUpperCase(), location.trim().toLowerCase()];
        } 
        else if (locationOnlyMatch) {
            sql = "SELECT name, contact, blood_group FROM donors WHERE LOWER(location) = ?";
            params = [query.trim().toLowerCase()];
        } 
        else {
            return res.json({ 
                reply: "Invalid query. Use format like 'A+, Chennai' or just a location name." 
            });
        }

        // If blood group or location search without hospital verification
        if (!validateHospitalDetails(hospitalDetails)) {
            return res.json({ 
                reply: "Please verify hospital details before searching for donors.",
                requireHospitalVerification: true
            });
        }

        db.query(sql, params, (err, results) => {
            if (err) {
                console.error("Chatbot Query Error:", err);
                return res.status(500).json({ 
                    reply: "Sorry, an error occurred while searching for donors." 
                });
            }

            if (results.length > 0) {
                let responseText = "Donors found:<br>";
                results.forEach(row => {
                    responseText += `${row.name} - ${row.contact} - ${row.blood_group || row.location}<br>`;
                });
                res.json({ reply: responseText });
            } else {
                res.json({ reply: "No donors found matching your request." });
            }
        });
    } catch (error) {
        console.error("Chatbot Processing Error:", error);
        res.status(500).json({ 
            reply: "An unexpected error occurred. Please try again." 
        });
    }
});

// Global error handler
app.use((err, req, res, next) => {
    console.error(err.stack);
    res.status(500).json({ 
        message: "Something went wrong!", 
        error: err.message 
    });
});

const PORT = process.env.PORT || 5000;
app.listen(PORT, () => {
    console.log(`Server running on port ${PORT}`);
});

module.exports = app;