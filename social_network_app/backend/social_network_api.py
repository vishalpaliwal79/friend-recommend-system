from flask import Flask, jsonify, request
from flask_cors import CORS
import networkx as nx
from collections import deque
import sqlite3
import os

app = Flask(__name__)
CORS(app)

class SocialNetworkDB:
    def __init__(self, db_path='social_network.db'):
        self.db_path = db_path
        self.graph = nx.Graph()
        self.users = {}
        self.init_database()
        self._load_data_from_db()
    
    def init_database(self):
        """Initialize SQLite database with tables"""
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()
        
        # Create users table
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS users (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                name TEXT NOT NULL UNIQUE,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        ''')
        
        # Create friendships table
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS friendships (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                user1_id INTEGER,
                user2_id INTEGER,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                FOREIGN KEY (user1_id) REFERENCES users (id),
                FOREIGN KEY (user2_id) REFERENCES users (id),
                UNIQUE(user1_id, user2_id)
            )
        ''')
        
        # Insert sample data if empty
        cursor.execute('SELECT COUNT(*) FROM users')
        if cursor.fetchone()[0] == 0:
            self._insert_sample_data(cursor)
        
        conn.commit()
        conn.close()
        print(f"✅ Database initialized: {self.db_path}")
    
    def _insert_sample_data(self, cursor):
        """Insert sample users and friendships"""
        sample_users = [
            "Alice", "Bob", "Charlie", "Diana", "Eve", 
            "Frank", "Grace", "Henry", "Ivy", "Jack",
            "Karen", "Leo", "Mia", "Nathan", "Olivia"
        ]
        
        # Insert users
        for name in sample_users:
            cursor.execute('INSERT OR IGNORE INTO users (name) VALUES (?)', (name,))
        
        # Define friendships (more balanced network)
        friendships = [
            (1, 2), (1, 3), (1, 4), (1, 5),
            (2, 3), (2, 4), (2, 6),
            (3, 4), (3, 7),
            (4, 5), (4, 8),
            (5, 9), (5, 10),
            (6, 11), (6, 12),
            (7, 13), (7, 14),
            (8, 15), (8, 1),
            (9, 10), (9, 11),
            (10, 12),
            (11, 13),
            (12, 14),
            (13, 15),
            (14, 15),
            (9, 1),
            (15, 2)
        ]
        
        # Insert friendships
        for user1_id, user2_id in friendships:
            try:
                cursor.execute(
                    'INSERT OR IGNORE INTO friendships (user1_id, user2_id) VALUES (?, ?)',
                    (user1_id, user2_id)
                )
            except sqlite3.IntegrityError:
                pass  # Friendship already exists
        
        print("📊 Sample data inserted into database")
    
    def _load_data_from_db(self):
        """Load users and friendships from database into graph"""
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()
        
        # Load users
        cursor.execute('SELECT id, name FROM users ORDER BY id')
        users = cursor.fetchall()
        self.users = {row[0]: row[1] for row in users}
        
        # Add users to graph
        for user_id, name in users:
            self.graph.add_node(user_id, name=name)
        
        # Load friendships
        cursor.execute('SELECT user1_id, user2_id FROM friendships')
        friendships = cursor.fetchall()
        
        # Add edges to graph
        for user1_id, user2_id in friendships:
            self.graph.add_edge(user1_id, user2_id)
        
        conn.close()
        print(f"📈 Loaded {len(self.users)} users and {len(friendships)} friendships from database")
    
    def add_user(self, name):
        """Add a new user to the database and graph"""
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()
        
        try:
            cursor.execute('INSERT INTO users (name) VALUES (?)', (name,))
            user_id = cursor.lastrowid
            conn.commit()
            
            # Update graph
            self.users[user_id] = name
            self.graph.add_node(user_id, name=name)
            
            print(f"✅ Added new user: {name} (ID: {user_id})")
            return user_id
        except sqlite3.IntegrityError:
            print(f"⚠️ User '{name}' already exists")
            return None
        finally:
            conn.close()
    
    def add_friendship(self, user1_id, user2_id):
        """Add a new friendship to the database and graph"""
        if user1_id not in self.users or user2_id not in self.users:
            print(f"❌ Invalid user IDs: {user1_id} or {user2_id}")
            return False
        
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()
        
        try:
            cursor.execute(
                'INSERT INTO friendships (user1_id, user2_id) VALUES (?, ?)',
                (user1_id, user2_id)
            )
            conn.commit()
            
            # Update graph
            self.graph.add_edge(user1_id, user2_id)
            print(f"✅ Added friendship: {self.users[user1_id]} ↔ {self.users[user2_id]}")
            return True
        except sqlite3.IntegrityError:
            print(f"⚠️ Friendship already exists: {self.users[user1_id]} ↔ {self.users[user2_id]}")
            return False
        finally:
            conn.close()
    
    def get_friends_within_degree(self, user_id, degree):
        """BFS to find friends within specified degree"""
        if user_id not in self.graph:
            return []
        
        visited = set()
        queue = deque([(user_id, 0)])
        visited.add(user_id)
        friends_within_degree = []
        
        while queue:
            current_user, current_degree = queue.popleft()
            
            if 2 <= current_degree <= degree:
                friends_within_degree.append((current_user, current_degree))
            
            if current_degree < degree:
                for neighbor in self.graph.neighbors(current_user):
                    if neighbor not in visited:
                        visited.add(neighbor)
                        queue.append((neighbor, current_degree + 1))
        
        return friends_within_degree
    
    def get_mutual_friends_count(self, user1_id, user2_id):
        """Count mutual friends between two users"""
        if user1_id not in self.graph or user2_id not in self.graph:
            return 0
        
        friends1 = set(self.graph.neighbors(user1_id))
        friends2 = set(self.graph.neighbors(user2_id))
        
        friends1.discard(user2_id)
        friends2.discard(user1_id)
        
        return len(friends1.intersection(friends2))
    
    def get_recommendations(self, user_id, degree=2):
        """Get friend recommendations"""
        friends_within_degree = self.get_friends_within_degree(user_id, degree)
        
        recommendations = []
        for friend_id, friend_degree in friends_within_degree:
            mutual_friends = self.get_mutual_friends_count(user_id, friend_id)
            
            if friend_degree == 2 and mutual_friends == 0:
                continue
                
            recommendations.append({
                'id': friend_id,
                'name': self.users[friend_id],
                'degree': friend_degree,
                'mutual_friends': mutual_friends
            })
        
        recommendations.sort(key=lambda x: (x['degree'], -x['mutual_friends']))
        return recommendations
    
    def get_network_data(self):
        """Get network data for visualization"""
        nodes = []
        edges = []
        
        for node in self.graph.nodes():
            nodes.append({
                'id': node,
                'label': self.users[node],
                'name': self.users[node]
            })
        
        for edge in self.graph.edges():
            edges.append({
                'from': edge[0],
                'to': edge[1]
            })
        
        return {'nodes': nodes, 'edges': edges}
    
    def get_database_stats(self):
        """Get database statistics"""
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()
        
        cursor.execute('SELECT COUNT(*) FROM users')
        user_count = cursor.fetchone()[0]
        
        cursor.execute('SELECT COUNT(*) FROM friendships')
        friendship_count = cursor.fetchone()[0]
        
        conn.close()
        
        return {
            'users_in_db': user_count,
            'friendships_in_db': friendship_count,
            'users_in_memory': len(self.users),
            'friendships_in_memory': len(self.graph.edges())
        }

# Initialize database-backed social network
social_network_db = SocialNetworkDB()

# API Routes
@app.route('/api/users', methods=['GET'])
def get_users():
    users = [{'id': uid, 'name': name} for uid, name in social_network_db.users.items()]
    return jsonify(users)

@app.route('/api/users', methods=['POST'])
def add_user():
    data = request.get_json()
    if not data or 'name' not in data:
        return jsonify({'error': 'Name is required'}), 400
    
    user_id = social_network_db.add_user(data['name'])
    if user_id:
        return jsonify({'id': user_id, 'name': data['name']}), 201
    else:
        return jsonify({'error': 'User already exists'}), 400

@app.route('/api/friendships', methods=['POST'])
def add_friendship():
    data = request.get_json()
    if not data or 'user1_id' not in data or 'user2_id' not in data:
        return jsonify({'error': 'user1_id and user2_id are required'}), 400
    
    success = social_network_db.add_friendship(data['user1_id'], data['user2_id'])
    if success:
        return jsonify({'message': 'Friendship added successfully'}), 201
    else:
        return jsonify({'error': 'Friendship already exists or invalid users'}), 400

@app.route('/api/recommendations/<int:user_id>', methods=['GET'])
def get_recommendations(user_id):
    degree = request.args.get('degree', 2, type=int)
    recommendations = social_network_db.get_recommendations(user_id, degree)
    return jsonify(recommendations)

@app.route('/api/network', methods=['GET'])
def get_network():
    network_data = social_network_db.get_network_data()
    return jsonify(network_data)

@app.route('/api/database/stats', methods=['GET'])
def get_database_stats():
    stats = social_network_db.get_database_stats()
    return jsonify(stats)

@app.route('/api/user/<int:user_id>', methods=['GET'])
def get_user(user_id):
    if user_id in social_network_db.users:
        return jsonify({
            'id': user_id,
            'name': social_network_db.users[user_id]
        })
    return jsonify({'error': 'User not found'}), 404

if __name__ == '__main__':
    print("🚀 Starting Social Network API with SQLite Database...")
    print("💾 Database file: social_network.db")
    app.run(host='172.21.160.167', port=9000, debug=True)