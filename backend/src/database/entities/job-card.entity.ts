import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
} from 'typeorm';

@Entity('job_cards')
export class JobCard {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column()
  bookingId: string;

  @Column()
  workshopId: string;

  @Column({ nullable: true })
  mechanicId: string;

  @Column({ length: 100 })
  customerName: string;

  @Column({ length: 50 })
  vehicleType: string;

  @Column({ length: 50 })
  vehicleNumber: string;

  @Column({ length: 100 })
  vehicleMake: string;

  @Column({ length: 100 })
  vehicleModel: string;

  @Column({ length: 100 })
  service: string;

  @Column({ type: 'simple-json', nullable: true })
  partsUsed: string[];

  @Column({ type: 'text', nullable: true })
  labourNotes: string;

  @Column({ type: 'decimal', precision: 10, scale: 2, default: 0 })
  laborCharges: number;

  @Column({ length: 20, default: 'active' })
  status: string; // 'active' | 'completed'

  @Column({ nullable: true })
  completedAt: Date;

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;
}
