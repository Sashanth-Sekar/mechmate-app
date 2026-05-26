import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
  ManyToOne,
  JoinColumn,
  OneToMany,
} from 'typeorm';
import { User } from './user.entity';
import { Booking } from './booking.entity';

@Entity('workshops')
export class Workshop {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ length: 200 })
  name: string;

  @Column({ type: 'text', nullable: true })
  description: string;

  @Column({ length: 255 })
  address: string;

  @Column({ length: 100 })
  city: string;

  @Column({ length: 20 })
  pincode: string;

  @Column({ type: 'decimal', precision: 10, scale: 7, nullable: true })
  latitude: number;

  @Column({ type: 'decimal', precision: 10, scale: 7, nullable: true })
  longitude: number;

  @Column({ length: 20, nullable: true })
  phone: string;

  @Column({ length: 100, nullable: true })
  email: string;

  @Column({ length: 50, nullable: true })
  gstNumber: string;

  // Working hours
  @Column({ length: 10, default: '09:00' })
  openTime: string;

  @Column({ length: 10, default: '18:00' })
  closeTime: string;

  @Column({ default: true })
  isOpen: boolean;

  // Ratings
  @Column({ type: 'decimal', precision: 2, scale: 1, default: 0 })
  rating: number;

  @Column({ default: 0 })
  reviewCount: number;

  // Vehicle types served
  @Column({ type: 'simple-json', nullable: true })
  vehicleTypes: string[];

  // Services offered
  @Column({ type: 'simple-json', nullable: true })
  services: string[];

  // Geo-location for hierarchical search
  @Column({ length: 100, nullable: true })
  country: string;

  @Column({ length: 10, nullable: true })
  countryCode: string;

  @Column({ length: 100, nullable: true })
  state: string;

  @Column({ length: 10, nullable: true })
  stateCode: string;

  @Column({ nullable: true })
  imageUrl: string;

  @Column({ type: 'simple-json', nullable: true })
  images: string[];

  // Available mechanics count
  @Column({ default: 0 })
  availableMechanics: number;

  @Column({ default: false })
  isVerified: boolean;

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;

  // Relations
  @ManyToOne(() => User, (user) => user.workshops)
  @JoinColumn({ name: 'ownerId' })
  owner: User;

  @Column()
  ownerId: string;

  @OneToMany(() => Booking, (booking) => booking.workshop)
  bookings: Booking[];
}
