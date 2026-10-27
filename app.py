"""Counter service used for the CI/CD final project.

The service exposes a tiny JSON API so the CI pipeline can exercise linting,
unit tests, container builds, and an OpenShift deployment without depending on
an external database.
"""

import logging
import os

from flask import Flask, jsonify
from flask_cors import CORS

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s %(levelname)s %(name)s %(message)s",
)
logger = logging.getLogger("cicd-app")

PORT = int(os.environ.get("PORT", "8000"))

app = Flask(__name__)
CORS(app)

counter = {"count": 0}

# WSGI alias used by the Python S2I builder (APP_MODULE=app:application).
application = app

logger.info("SERVICERUNNING cicd-app listening on port %d", PORT)


@app.get("/")
def index():
    """Return service metadata."""
    return jsonify(
        project="ci-cd-final-project",
        service="cicd-app",
        status="OK",
        port=PORT,
    )


@app.get("/health")
def health():
    """Health probe used by GitHub Actions and OpenShift."""
    return jsonify(status="OK")


@app.get("/count")
def get_count():
    """Return the current counter value."""
    return jsonify(count=counter["count"])


@app.post("/count")
def increment_count():
    """Increment the counter by one."""
    counter["count"] += 1
    return jsonify(count=counter["count"])


@app.delete("/count")
def reset_count():
    """Reset the counter to zero."""
    counter["count"] = 0
    return jsonify(count=counter["count"])


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=PORT)
