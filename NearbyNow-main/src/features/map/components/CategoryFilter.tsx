import { useState } from 'react';
import { usePlacesContext } from '../../places/context/PlacesContext';

const categories = ['All', 'Cafe', 'Shop', 'Restaurant'];

export function CategoryFilter() {
//   const [selected, setSelected] = useState('All');
//   const { setCategoryFilter } = usePlacesContext();

//   const handleSelect = (category: string) => {
//     setSelected(category);
//     setCategoryFilter(category);
//   };

//   return (
//     <div className="absolute top-20 left-1/2 transform -translate-x-1/2 z-[1000] bg-white p-2 rounded-md shadow-md flex gap-2">
//       {categories.map((cat) => (
//         <button
//           key={cat}
//           onClick={() => handleSelect(cat)}
//           className={`p-2 rounded ${selected === cat ? 'bg-blue-500 text-white' : 'bg-gray-200'}`}
//         >
//           {cat}
//         </button>
//       ))}
//     </div>
//   );
}

