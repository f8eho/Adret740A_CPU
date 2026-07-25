#!/usr/bin/env python3
"""Point d'entrée historique vers l'application de calibration unifiée."""

import sys

from adret_calibration import main


if __name__ == "__main__":
    sys.exit(main(["import", *sys.argv[1:]]))
