#!/usr/bin/env python3
"""
Cortex Agent REST API Client

Uses JWT authentication with key-pair to call Snowflake Cortex Agents
via the REST API with SSE streaming.
"""

import json
import time
import hashlib
import base64
import requests
import urllib3

import jwt
from cryptography.hazmat.backends import default_backend
from cryptography.hazmat.primitives import serialization

urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)


class JWTGenerator:
    """Generate JWT tokens for Snowflake REST API authentication."""
    
    def __init__(self, account: str, user: str, private_key_path: str):
        self.account = account.upper()
        self.user = user.upper()
        self.private_key_path = private_key_path
        self._private_key = None
        self._public_key_fp = None
    
    def _load_private_key(self):
        if self._private_key is None:
            with open(self.private_key_path, "rb") as key_file:
                self._private_key = serialization.load_pem_private_key(
                    key_file.read(),
                    password=None,
                    backend=default_backend()
                )
            public_key = self._private_key.public_key()
            public_key_bytes = public_key.public_bytes(
                serialization.Encoding.DER,
                serialization.PublicFormat.SubjectPublicKeyInfo
            )
            sha256hash = hashlib.sha256()
            sha256hash.update(public_key_bytes)
            self._public_key_fp = "SHA256:" + base64.b64encode(sha256hash.digest()).decode('utf-8')
        return self._private_key
    
    def get_token(self) -> str:
        """Generate a new JWT token."""
        private_key = self._load_private_key()
        qualified_username = f"{self.account}.{self.user}"
        now = int(time.time())
        payload = {
            "iss": f"{qualified_username}.{self._public_key_fp}",
            "sub": qualified_username,
            "iat": now,
            "exp": now + 3600,
        }
        return jwt.encode(payload, private_key, algorithm="RS256")


class CortexAgentClient:
    """Client for calling Cortex Agents via REST API."""
    
    def __init__(self, account: str, user: str, private_key_path: str,
                 database: str, schema: str, agent_name: str):
        self.account = account
        self.database = database
        self.schema = schema
        self.agent_name = agent_name
        self.jwt_gen = JWTGenerator(account, user, private_key_path)
        self.host = f"{account}.snowflakecomputing.com"
    
    def ask(self, question: str, verbose: bool = False) -> dict:
        """
        Send a question to the agent and return the response.
        
        Returns dict with: answer, sql, tools_used, result_set, duration, error
        """
        start_time = time.time()
        
        url = f"https://{self.host}/api/v2/databases/{self.database}/schemas/{self.schema}/agents/{self.agent_name}:run"
        
        headers = {
            "Authorization": f"Bearer {self.jwt_gen.get_token()}",
            "X-Snowflake-Authorization-Token-Type": "KEYPAIR_JWT",
            "Content-Type": "application/json",
            "Accept": "text/event-stream",
        }
        
        payload = {
            "messages": [
                {"role": "user", "content": [{"type": "text", "text": question}]}
            ]
        }
        
        if verbose:
            print(f"URL: {url}")
            print(f"Question: {question}")
        
        result = {
            "answer": "",
            "sql": None,
            "tools_used": [],
            "result_set": None,
            "error": None,
            "raw_events": [],
        }
        
        try:
            response = requests.post(
                url, headers=headers, json=payload,
                stream=True, verify=False, timeout=180
            )
            
            if response.status_code != 200:
                result["error"] = f"HTTP {response.status_code}: {response.text[:500]}"
                result["duration"] = time.time() - start_time
                return result
            
            # Parse SSE stream
            current_event = None
            
            for line in response.iter_lines(decode_unicode=True):
                if not line:
                    continue
                
                if line.startswith("event:"):
                    current_event = line[6:].strip()
                    continue
                
                if not line.startswith("data:"):
                    continue
                
                data_str = line[5:].strip()
                if data_str == "[DONE]":
                    break
                
                try:
                    data = json.loads(data_str)
                    
                    if verbose:
                        result["raw_events"].append({"event": current_event, "data": data})
                    
                    # Handle error events
                    if current_event == "error":
                        result["error"] = data.get("message", str(data))
                        continue
                    
                    # Extract streaming text
                    if current_event == "response.text.delta" and "text" in data:
                        result["answer"] += data["text"]
                    
                    # Extract tool results
                    if current_event == "response.tool_result":
                        tool_type = data.get("type", "")
                        if tool_type and tool_type not in result["tools_used"]:
                            result["tools_used"].append(tool_type)
                        
                        # Extract SQL from analyst results
                        for item in data.get("content", []):
                            if isinstance(item, dict) and "json" in item:
                                json_data = item["json"]
                                if "sql" in json_data:
                                    result["sql"] = json_data["sql"]
                                if "result_set" in json_data:
                                    result["result_set"] = json_data["result_set"]
                    
                    # Extract from response.table
                    if current_event == "response.table" and "result_set" in data:
                        result["result_set"] = data["result_set"]
                    
                    # Final response content
                    if current_event == "response" and "content" in data:
                        for item in data["content"]:
                            if item.get("type") == "text" and not result["answer"]:
                                result["answer"] = item.get("text", "")
                    
                except json.JSONDecodeError:
                    continue
        
        except Exception as e:
            result["error"] = str(e)
        
        result["duration"] = time.time() - start_time
        return result
    
    def format_result(self, result: dict) -> str:
        """Format result for display."""
        lines = [f"\n{'='*60}"]
        lines.append(f"Duration: {result.get('duration', 0):.1f}s")
        
        if result.get("error"):
            lines.append(f"ERROR: {result['error']}")
        
        if result.get("tools_used"):
            lines.append(f"Tools: {', '.join(result['tools_used'])}")
        
        lines.append(f"\nAnswer:\n{result.get('answer', 'No answer')}")
        
        if result.get("sql"):
            sql = result['sql'][:400] + "..." if len(result['sql']) > 400 else result['sql']
            lines.append(f"\nSQL:\n{sql}")
        
        if result.get("result_set"):
            data = result["result_set"].get("data", [])
            lines.append(f"\nResult: {len(data)} rows")
            for row in data[:5]:
                lines.append(f"  {row}")
            if len(data) > 5:
                lines.append(f"  ... and {len(data) - 5} more")
        
        lines.append('='*60)
        return '\n'.join(lines)
