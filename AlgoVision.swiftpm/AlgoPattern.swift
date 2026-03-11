import SwiftUI

enum PatternType: String {
    case binarySearch = "Binary Search"
    case twoPointers = "Two Pointers"
    case slidingWindow = "Sliding Window"
    case bfs = "Breadth-First Search"
}

struct AlgoPattern: Identifiable, Hashable {
    var id: String { type.rawValue }
    let type: PatternType
    let title: String
    let subtitle: String
    let icon: String
    let accent: Color
    let accentSecondary: Color
    
    let description: String
    let coreIdea: String
    let whenToUse: String
    let timeComplexity: String
    let spaceComplexity: String
}

let patterns: [AlgoPattern] = [
    AlgoPattern(
        type: .binarySearch,
        title: "Binary Search",
        subtitle: "Divide & Conquer in O(log n)",
        icon: "magnifyingglass",
        accent: Color(red: 0.6, green: 0.3, blue: 1.0),
        accentSecondary: Color(red: 0.8, green: 0.4, blue: 1.0),
        description: "Binary Search is a classic divide-and-conquer algorithm that efficiently locates a target value within a sorted array. By repeatedly halving the search space, it dramatically reduces the number of comparisons needed.",
        coreIdea: "Compare the target with the middle element. If it matches, you're done. If the target is smaller, search the left half. If larger, search the right half. Repeat until found.",
        whenToUse: "Use when searching in a sorted collection. If the data is ordered, you can eliminate half the remaining elements in a single comparison.",
        timeComplexity: "O(log n) – halves the search space each step. ~30 steps for 1 billion items.",
        spaceComplexity: "O(1) iterative, O(log n) recursive – only pointers needed, no extra data structures."
    ),
    AlgoPattern(
        type: .twoPointers,
        title: "Two Pointers",
        subtitle: "Shrink the window in O(n)",
        icon: "arrow.left.and.right",
        accent: Color(red: 0.0, green: 0.8, blue: 1.0),
        accentSecondary: Color(red: 0.2, green: 0.6, blue: 1.0),
        description: "The Two Pointers technique involves using two references (or pointers) to iterate through a data structure, typically to find pairs or sequences that satisfy a specific condition efficiently.",
        coreIdea: "Start with two pointers at different positions (e.g., beginning and end). Move them towards each other or in the same direction based on the problem constraints until the condition is met.",
        whenToUse: "Ideal for sorted arrays or linked lists when you need to find pairs with a specific sum, remove duplicates, or reverse a sequence without extra memory.",
        timeComplexity: "O(n) – each element is visited at most once by each pointer, providing a linear time solution.",
        spaceComplexity: "O(1) – only a few variables are needed to store the pointer indices, ensuring constant space usage."
    ),
    AlgoPattern(
        type: .slidingWindow,
        title: "Sliding Window",
        subtitle: "Expand & shrink a range in O(n)",
        icon: "square.stack.3d.up",
        accent: Color(red: 0.0, green: 0.9, blue: 0.7),
        accentSecondary: Color(red: 0.1, green: 0.7, blue: 0.6),
        description: "The Sliding Window technique is used to perform operations on a specific subset of elements in a sequence, like an array or string. It involves creating a 'window' that slides over the data to efficiently calculate results.",
        coreIdea: "Maintain a window of elements. Expand the window by adding elements from the right, and shrink it from the left when a condition is violated, keeping track of the optimal result.",
        whenToUse: "Perfect for problems asking for the longest/shortest subarray or substring that satisfies a certain condition, or for calculating running totals.",
        timeComplexity: "O(n) – both the left and right boundaries of the window move forward at most n times.",
        spaceComplexity: "O(k) or O(1) – depending on whether you need a data structure to keep track of elements inside the window."
    ),
    AlgoPattern(
        type: .bfs,
        title: "Breadth-First Search",
        subtitle: "Level-by-level exploration",
        icon: "arrow.triangle.branch",
        accent: Color(red: 1.0, green: 0.55, blue: 0.1),
        accentSecondary: Color(red: 1.0, green: 0.4, blue: 0.1),
        description: "Breadth-First Search (BFS) is an algorithm for traversing or searching tree or graph data structures. It explores all the neighbor nodes at the present depth prior to moving on to the nodes at the next depth level.",
        coreIdea: "Use a queue to keep track of nodes to visit. Start at the root, push it to the queue. While the queue is not empty, pop a node, process it, and push all its unvisited neighbors to the queue.",
        whenToUse: "Use when you need to find the shortest path on an unweighted graph, or when you want to explore all states reachable in minimum steps.",
        timeComplexity: "O(V + E) – where V is the number of vertices and E is the number of edges. Each vertex and edge is visited once.",
        spaceComplexity: "O(V) – the queue can contain all the vertices of the widest level of the graph."
    )
]
