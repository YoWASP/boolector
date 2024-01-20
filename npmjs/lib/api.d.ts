export type Tree = {
    [name: string]: Tree | string | Uint8Array
};

export type OutputStream =
    (bytes: Uint8Array | null) => void;

export class Exit extends Error {
    code: number;
    files: Tree;
}

export type Command = (args?: string[], files?: Tree, options?: {
    stdout?: OutputStream | null,
    stderr?: OutputStream | null,
    decodeASCII?: boolean
}) => Promise<Tree>;

export const runBoolector: Command;

export const commands: {
    'boolector': Command,
};
