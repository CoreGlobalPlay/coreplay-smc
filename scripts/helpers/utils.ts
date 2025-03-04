import * as fs from "fs/promises";

export async function readFileToArray(filePath: string): Promise<string[]> {
  const data = await fs.readFile(filePath, "utf-8");

  const lines: string[] = data
    .split("\n")
    .map((line) => line.trim())
    .filter((line) => line.length > 0);

  return lines;
}
