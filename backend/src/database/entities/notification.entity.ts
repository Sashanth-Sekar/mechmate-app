import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
} from 'typeorm';

@Entity('notifications')
export class Notification {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column()
  userId: string;

  @Column({ length: 100 })
  title: string;

  @Column({ type: 'text', nullable: true })
  body: string;

  @Column({ length: 50, nullable: true })
  type: string; // 'booking_update' | 'payment' | 'reminder' | 'promo'

  @Column({ length: 100, nullable: true })
  referenceId: string;

  @Column({ default: false })
  isRead: boolean;

  @CreateDateColumn()
  createdAt: Date;
}
