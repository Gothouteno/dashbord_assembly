'use client';

import { useEffect, useState } from 'react';
import { useAuth } from '@/contexts/auth-context';
import { useRouter } from 'next/navigation';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { AdminUserTable } from '@/components/admin-user-table';
import { ModernSidebar } from '@/components/modern-sidebar';
import { ThemeToggle } from '@/components/theme-toggle';
import { UserProfileDropdown } from '@/components/user-profile-dropdown';
import { Users, UserPlus, Archive, Trash2 } from 'lucide-react';
import { supabase } from '@/lib/supabase';
import { toast } from '@/hooks/use-toast';

export default function AdminPage() {
  const { user, profile, loading, isAdmin } = useAuth();
  const router = useRouter();
  const [totalUsers, setTotalUsers] = useState(0);

  useEffect(() => {
    if (!loading && (!user || !isAdmin)) {
      router.push('/login');
    }
  }, [user, isAdmin, loading, router]);

  useEffect(() => {
    loadStats();
  }, []);

  const loadStats = async () => {
    const { count } = await supabase
      .from('user_profiles')
      .select('*', { count: 'exact', head: true });
    setTotalUsers(count || 0);
  };

  if (loading || !user || !isAdmin) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <div className="animate-spin rounded-full h-12 w-12 border-t-2 border-b-2 border-blue-500"></div>
      </div>
    );
  }

  return (
    <div className="flex h-screen overflow-hidden bg-gray-50 dark:bg-gray-900">
      <ModernSidebar />

      <div className="flex-1 overflow-auto">
        <header className="sticky top-0 z-10 backdrop-blur-md bg-white/80 dark:bg-gray-900/80 border-b border-gray-200 dark:border-gray-800">
          <div className="flex items-center justify-between px-6 py-4">
            <div>
              <h1 className="text-2xl font-bold text-gray-900 dark:text-white">
                User Management
              </h1>
              <p className="text-sm text-gray-500 dark:text-gray-400">
                Manage all users in the system
              </p>
            </div>
            <div className="flex items-center space-x-4">
              <ThemeToggle />
              <UserProfileDropdown />
            </div>
          </div>
        </header>

        <main className="p-6 space-y-6">
          <div className="flex items-center justify-between">
            <div className="flex items-center space-x-2">
              <h2 className="text-xl font-semibold">
                All Users: {totalUsers.toLocaleString()}
              </h2>
              <span className="text-sm text-gray-500">
                Projects: 884
              </span>
            </div>
            <div className="flex items-center space-x-2">
              <Button variant="outline">Suspend all</Button>
              <Button variant="outline">Archive all</Button>
              <Button variant="destructive">Delete all</Button>
              <Button>
                <UserPlus className="w-4 h-4 mr-2" />
                Add new user
              </Button>
            </div>
          </div>

          <Card>
            <CardHeader>
              <CardTitle>Users List</CardTitle>
              <CardDescription>
                View and manage all registered users
              </CardDescription>
            </CardHeader>
            <CardContent>
              <AdminUserTable />
            </CardContent>
          </Card>

          <div className="flex items-center justify-between text-sm text-gray-500">
            <span>Rows per page: 10</span>
            <div className="flex items-center space-x-4">
              <span>1-10 of 100</span>
              <div className="flex space-x-2">
                <Button variant="outline" size="icon">
                  1
                </Button>
                <Button variant="outline" size="icon">
                  2
                </Button>
                <Button variant="outline" size="icon">
                  3
                </Button>
                <span>...</span>
                <Button variant="outline" size="icon">
                  100
                </Button>
                <Button variant="outline" size="icon">
                  →
                </Button>
              </div>
            </div>
          </div>
        </main>
      </div>
    </div>
  );
}
