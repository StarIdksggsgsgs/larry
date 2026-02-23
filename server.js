const express = require("express");
const fs = require("fs");
const { execFile } = require("child_process");
const path = require("path");
const crypto = require("crypto");

const app = express();
app.use(express.text({ limit: "5mb" }));

const PORT = process.env.PORT || 10000;

app.post("/", (req, res) => {
    const inputCode = req.body;

    if (!inputCode) {
        return res.status(400).send("No code provided");
    }

    const id = crypto.randomUUID();
    const inputFile = path.join("/tmp", `input_${id}.lua`);
    const outputFile = path.join("/tmp", `output_${id}.lua`);

    fs.writeFileSync(inputFile, inputCode);

    execFile("lua", ["catnapdumper.lua", inputFile, outputFile], { timeout: 30000 }, (error) => {
        if (error) {
            return res.status(500).send("Execution error");
        }

        if (!fs.existsSync(outputFile)) {
            return res.status(500).send("Output not created");
        }

        let output = fs.readFileSync(outputFile, "utf8");

        // Escape quotes & wrap
        output = output.replace(/"/g, '\\"');
        output = `CODE: "${output}"`;

        fs.unlinkSync(inputFile);
        fs.unlinkSync(outputFile);

        res.type("text/plain").send(output);
    });
});

app.listen(PORT, () => {
    console.log("API running on port", PORT);
});
