## 1. Structural Section Headers

- [x] 1.1 Add section header for "Configuration & Defaults".
- [x] 1.2 Add section header for "Dotenv Parsing".
- [x] 1.3 Add section header for "Utility Functions".
- [x] 1.4 Add section header for "OCI Auth & Validation".
- [x] 1.5 Add section header for "OCI CLI Auto-Install".
- [x] 1.6 Add section header for "OCI Resource Lookup".
- [x] 1.7 Add section header for "Artifact Generation".
- [x] 1.8 Add section header for "CLI Argument Parsing".
- [x] 1.9 Add section header for "Main Execution & Retry Loop".

## 2. Function and Logic Comments

- [x] 2.1 Comment the `strip_dotenv_comment` and `parse_dotenv_value` functions to explain the manual string processing.
- [x] 2.2 Comment `extract_instance_id` to explain the `sed` regex used for JSON parsing.
- [x] 2.3 Comment `is_capacity_error` to explain the strings it looks for.
- [x] 2.4 Comment the file permissions logic (`chmod 600`) in `copy_private_key_artifact` and `print_api_key_auth_guidance`.
