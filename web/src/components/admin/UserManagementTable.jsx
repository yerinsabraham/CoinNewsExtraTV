import React from 'react';
import { Shield, Ban, Edit, Trash2 } from 'lucide-react';
import { formatDistanceToNow } from 'date-fns';

const UserManagementTable = ({ users, onBanUser, onEditBalance, onDeleteUser }) => {
  return (
    <div className="overflow-x-auto">
      <table className="w-full">
        <thead>
          <tr className="border-b border-gray-700">
            <th className="text-left py-3 px-4 text-gray-400 font-medium">User</th>
            <th className="text-left py-3 px-4 text-gray-400 font-medium">Email</th>
            <th className="text-right py-3 px-4 text-gray-400 font-medium">Balance</th>
            <th className="text-left py-3 px-4 text-gray-400 font-medium">Status</th>
            <th className="text-left py-3 px-4 text-gray-400 font-medium">Joined</th>
            <th className="text-right py-3 px-4 text-gray-400 font-medium">Actions</th>
          </tr>
        </thead>
        <tbody>
          {users.map((user) => {
            const joinedDate = user.createdAt?.toDate ? user.createdAt.toDate() : new Date();
            const avatarUrl = user.photoURL || `https://ui-avatars.com/api/?name=${encodeURIComponent(user.displayName || 'User')}&background=random`;
            
            return (
              <tr key={user.id} className="border-b border-gray-800 hover:bg-gray-800/50 transition-colors">
                <td className="py-3 px-4">
                  <div className="flex items-center gap-3">
                    <img src={avatarUrl} alt={user.displayName} className="w-10 h-10 rounded-full" />
                    <div>
                      <p className="text-white font-medium">{user.displayName || 'Anonymous'}</p>
                      {user.role === 'admin' && (
                        <span className="text-xs bg-purple-500/20 text-purple-400 px-2 py-0.5 rounded">Admin</span>
                      )}
                    </div>
                  </div>
                </td>
                <td className="py-3 px-4 text-gray-400">{user.email}</td>
                <td className="py-3 px-4 text-right">
                  <span className="text-yellow-400 font-semibold">{(user.balance || 0).toLocaleString()}</span>
                  <span className="text-gray-500 ml-1">CNE</span>
                </td>
                <td className="py-3 px-4">
                  {user.banned ? (
                    <span className="text-xs bg-red-500/20 text-red-400 px-2 py-1 rounded">Banned</span>
                  ) : (
                    <span className="text-xs bg-green-500/20 text-green-400 px-2 py-1 rounded">Active</span>
                  )}
                </td>
                <td className="py-3 px-4 text-gray-400 text-sm">
                  {formatDistanceToNow(joinedDate, { addSuffix: true })}
                </td>
                <td className="py-3 px-4">
                  <div className="flex items-center justify-end gap-2">
                    <button
                      onClick={() => onEditBalance(user)}
                      className="p-2 bg-blue-500/20 text-blue-400 hover:bg-blue-500/30 rounded transition-colors"
                      title="Edit Balance"
                    >
                      <Edit className="w-4 h-4" />
                    </button>
                    <button
                      onClick={() => onBanUser(user)}
                      className={`p-2 ${user.banned ? 'bg-green-500/20 text-green-400 hover:bg-green-500/30' : 'bg-orange-500/20 text-orange-400 hover:bg-orange-500/30'} rounded transition-colors`}
                      title={user.banned ? 'Unban User' : 'Ban User'}
                    >
                      {user.banned ? <Shield className="w-4 h-4" /> : <Ban className="w-4 h-4" />}
                    </button>
                    <button
                      onClick={() => onDeleteUser(user)}
                      className="p-2 bg-red-500/20 text-red-400 hover:bg-red-500/30 rounded transition-colors"
                      title="Delete User"
                    >
                      <Trash2 className="w-4 h-4" />
                    </button>
                  </div>
                </td>
              </tr>
            );
          })}
        </tbody>
      </table>
    </div>
  );
};

export default UserManagementTable;
