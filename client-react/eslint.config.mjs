/**
 * Copyright (c) 2024, Daily.
 *
 * SPDX-License-Identifier: BSD-2-Clause
 */

import jsRecommended from "@eslint/js";
import tsRecommended from "@typescript-eslint/eslint-plugin";
import tsParser from "@typescript-eslint/parser";
import reactHooks from "eslint-plugin-react-hooks";
import simpleImportSort from "eslint-plugin-simple-import-sort";
import globals from "globals";

export default [
  {
    files: ["**/*.{mjs,ts,tsx}"],
    ignores: ["**/dist/**", "dist/**"],

    languageOptions: {
      parser: tsParser,
      globals: globals.browser,
    },

    plugins: {
      "simple-import-sort": simpleImportSort,
      "react-hooks": reactHooks,
      "@typescript-eslint": tsRecommended,
    },

    rules: {
      "simple-import-sort/imports": "error",
      "simple-import-sort/exports": "error",
      "react-hooks/rules-of-hooks": "error",
      "react-hooks/exhaustive-deps": "warn",
      ...jsRecommended.configs.recommended.rules,
      ...tsRecommended.configs.recommended.rules,
    },
  },
];
