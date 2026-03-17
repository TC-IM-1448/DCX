# DCX---Schema

## Introduction

DCX (Digital Calibration Exchange) provides the XML Schema Definition used to structure digital calibration documents in a consistent, machine-readable format. The schema supports calibration certificates, test and measurement reports, requests, and reusable templates.

This repository focuses on the schema foundation behind DCX workflows. It defines the core data model for administrative metadata, equipment, settings, measurement configurations, measurement results, quantity and unit definitions, and embedded files. It also includes integrity rules (keys and keyrefs) to ensure references between elements remain valid.

The design is inspired by practical implementation work from DCC-Tables and is intended to support robust data exchange between laboratories, service providers, clients, and software systems.

