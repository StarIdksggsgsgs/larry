from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
import subprocess
import uuid
import os

app = FastAPI()

class LuaRequest(BaseModel):
    code: str

@app.post("/run")
def run_lua(req: LuaRequest):
    try:
        unique_id = str(uuid.uuid4())
        input_file = f"/tmp/input_{unique_id}.lua"
        output_file = f"/tmp/output_{unique_id}.lua"

        # Write input
        with open(input_file, "w", encoding="utf-8") as f:
            f.write(req.code)

        # Run your Lua script
        process = subprocess.run(
            ["lua", "catnapdumper.lua", input_file, output_file],
            capture_output=True,
            text=True,
            timeout=30
        )

        if process.returncode != 0:
            return {
                "error": process.stderr
            }

        # Read output
        if not os.path.exists(output_file):
            raise HTTPException(status_code=500, detail="Output file not created")

        with open(output_file, "r", encoding="utf-8") as f:
            output_code = f.read()

        # Cleanup
        os.remove(input_file)
        os.remove(output_file)

        return {
            "output": output_code
        }

    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
