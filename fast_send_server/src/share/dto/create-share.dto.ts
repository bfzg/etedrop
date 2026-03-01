export class CreateShareDto {
  path!: string;
  fileName!: string;
  size!: number;
  password?: string;
  expiresIn?: number;
}
