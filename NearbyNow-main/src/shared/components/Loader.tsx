import { ClipLoader } from 'react-spinners';

export function Loader() {
  return (
    <div className="flex items-center justify-center h-screen">
      <ClipLoader size={50} color="#4A90E2" />
    </div>
  );
}
