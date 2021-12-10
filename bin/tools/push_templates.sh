#!/usr/bin/env bash

set -o errexit
set -o pipefail

source bin/env.sh

## Push mapping for artefact server metadatas
curl -X PUT -u ${ES_USER}:${ES_PASSWORD} "http://${ELASTICSEARCH_EXTERNAL_API_URL}/_template/template_1" -H 'Content-Type: application/json' -d'
{
  "order": 10,
  "index_patterns": [
    "*artifacts-metadata*"
  ],
  "settings": {
    "index": {
      "refresh_interval": "-1"
    }
  },
  "mappings": {
    "date_detection": true,
    "numeric_detection": false,
    "dynamic_templates": [
      {
        "strings_as_keywords": {
          "match_mapping_type": "string",
          "mapping": {
            "type": "keyword",
            "ignore_above": 256
          }
        }
      }
    ],
    "properties": {
"@timestamp": {
        "type": "date",
        "format": "epoch_millis||strictDateOptionalTime"
      },

      "artifact": {
        "type": "keyword"
      },
      "group": {
        "type": "keyword"
      },
      "version": {
        "type": "keyword"
      },
      "type": {
        "type": "keyword"
      },
      "description": {
        "type": "text"
      },
      "displayName": {
        "type": "keyword"
      },
      "createdAt": {
        "type": "keyword"
      },
      "readme": {
        "type": "text"
      },
      "changelog": {
        "type": "text"
      }
    }
  }
}
'