import { UsersService } from './users.service';
import { CreateUserDto } from './dto/create-user.dto';
export declare class UsersController {
    private usersService;
    constructor(usersService: UsersService);
    register(dto: CreateUserDto): Promise<import("./entities/user.entity").User>;
    getOne(id: string): Promise<import("./entities/user.entity").User>;
    uploadPhoto(file: Express.Multer.File, req: any): Promise<{
        success: boolean;
        message: string;
        data: {
            photoUrl: string;
        };
    }>;
}
