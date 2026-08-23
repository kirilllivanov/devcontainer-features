import js from "@eslint/js";
import json from "@eslint/json";
import { defineConfig, globalIgnores } from "eslint/config";
import prettierRecommended from "eslint-plugin-prettier/recommended";

const javascriptFiles = ["**/*.mjs"];
const jsonFiles = ["**/*.json"];
const jsoncFiles = [
  "**/*.jsonc",
  ".devcontainer/devcontainer.json",
  ".vscode/*.json"
];

export default defineConfig([
  globalIgnores(["package-lock.json"]),
  {
    ...js.configs.recommended,
    files: javascriptFiles
  },
  {
    files: jsonFiles,
    ignores: jsoncFiles,
    plugins: { json },
    language: "json/json",
    extends: ["json/recommended"]
  },
  {
    files: jsoncFiles,
    plugins: { json },
    language: "json/jsonc",
    extends: ["json/recommended"]
  },
  {
    ...prettierRecommended,
    files: [...javascriptFiles, ...jsonFiles, ...jsoncFiles],
    rules: {
      ...prettierRecommended.rules,
      "prettier/prettier": ["error", { trailingComma: "none" }]
    }
  }
]);
