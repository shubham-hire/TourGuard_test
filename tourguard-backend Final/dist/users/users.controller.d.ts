import { UsersService } from './users.service';
import { CreateUserDto } from './dto/create-user.dto';
export declare class UsersController {
    private usersService;
    constructor(usersService: UsersService);
    register(dto: CreateUserDto): Promise<{
        success: boolean;
        message: string;
        data: {
            id: string;
            name: string;
            email: string;
            phone: string;
            token: string;
        };
    }>;
    getOne(id: string): Promise<import("./entities/user.entity").User>;
    uploadPhoto(file: Express.Multer.File, req: any): Promise<{
        success: boolean;
        message: string;
        data: {
            photoUrl: string;
        };
    }>;
    updateLocation(body: {
        lat: number;
        lng: number;
    }, req: any): Promise<{
        success: boolean;
        message: string;
    }>;
    logActivity(body: {
        action: string;
        metadata?: any;
    }, req: any): Promise<{
        success: boolean;
        message: string;
    }>;
}
